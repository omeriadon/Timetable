//
//   SettingsView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import ColorfulX
import Defaults
import SwiftUI
import WidgetKit

#if os(iOS)

	struct SettingsView: View {
		@Default(.timetable) var subjects
		@Default(.lastServerSync) var lastServerSync
		@Default(.userDisplayName) var userDisplayName

		@Environment(\.statusBadgeManager) private var statusBadgeManager
		@State private var sessionStore = SessionStore.shared
		@State private var networkManager = NetworkManager.shared
		@State private var settings = Defaults[.accountSettings]
		@State private var committedSettings = Defaults[.accountSettings]
		@State private var settingsSync = AccountSettingsSyncService.shared
		@State private var settingsSaveGeneration = 0
		@Default(.debugOffset) private var debugOffset

		let watchSync: PhoneWatchSyncBridge

		@Binding var syncStatus: SyncMode

		@State private var showCalendarImportSheet = false
		@State private var showEditTimetableSheet = false
		@State private var ownerIsSearchable = Defaults[.ownerIsSearchable]
		@State private var committedOwnerIsSearchable = Defaults[.ownerIsSearchable]
		@State private var visibilitySaveGeneration = 0
		@State private var showFeedbackSheet = false
		@State private var showImportConfirmation = false

		@State private var colors = [
			Color.brown,
			Color(uiColor: .secondarySystemGroupedBackground),
			Color(uiColor: .secondarySystemGroupedBackground),
			Color(uiColor: .secondarySystemGroupedBackground),
			Color(uiColor: .secondarySystemGroupedBackground),
		]
		@State private var speed = 0.6
		@State private var colorTransitionSpeed = 10.0

		@Namespace private var ns

		init(watchSync: PhoneWatchSyncBridge, syncStatus: Binding<SyncMode>) {
			self.watchSync = watchSync
			_syncStatus = syncStatus
		}

		var body: some View {
			NavigationStack {
				Group {
					if #available(iOS 27.0, *) {
						List { list }
							.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
							.toolbarMinimizationSafeAreaAdjustment(.disabled, for: .navigationBar)
							.listStyle(.sidebar)
					} else {
						List { list }
							.listStyle(.sidebar)
					}
				}
				.scrollEdgeEffect(offset: 0.95, maxBlurRadius: 1, maximumOpacity: 0.2)
				.scrollEdgeEffectStyle(.soft, for: .top)
				.scrollContentBackground(.hidden)
				.appNavigationTitle("Settings", style: .main, accent: true)
			}
		}

		private var accountBackground: some View {
			AccountBackgroundView(profile: Defaults[.accountProfile])
		}

		private struct AccountBackgroundView: View {
			let profile: AccountProfile?

			@State private var colours: [Color] = [.black, .black]
			@State private var noise: Double = 0
			@State private var speed: Double = 0

			var body: some View {
				ColorfulView(
					color: .constant(colours),
					speed: .constant(speed),
					bias: .constant(0.000000000000001),
					noise: .constant(noise),
					transitionSpeed: .constant(4),
					renderScale: .constant(3)
				)
				.task(id: profile?.id) {
					guard let profile else { return }
					let loaded = await profile.profilePictureColours()
					colours = loaded.map(\.swiftUIColor)
					noise = profile.profilePictureNoise
					speed = profile.profilePictureSpeed
				}
			}
		}

		@ContentBuilder
		private var list: some View {
			Section {
				NavigationLink {
					AccountView()
				} label: {
					Label {
						Text(userDisplayName)
							.font(.title)
					} icon: {
						ProfilePicture(size: 50, accessibilityName: "Profile Picture")
							.padding(.trailing)
					}
					.padding(.leading, 10)
				}
				.listRowBackground(accountBackground)
			}

			Section("My Timetable") {
				Button {
					showImportConfirmation = true
				} label: {
					HStack(alignment: .center) {
						Image(systemName: "calendar")
							.foregroundStyle(.tint)
							.imageScale(.large)
							.padding(.trailing, 10)

						VStack(alignment: .leading) {
							Text("Re-import from Calendar")
								.foregroundStyle(.accent)
							Text("Subscribe to Compass Schedule in Calendar first.")
								.foregroundStyle(.secondary)
								.font(.callout)
						}
					}
				}
				.confirmationDialog(Text("Import timetable from Calendar again?"), isPresented: $showImportConfirmation, titleVisibility: .visible, actions: {
					Button("Yes", role: .confirm) {
						showCalendarImportSheet = true
					}
					Button("No", role: .cancel) {}

				}, message: {
					Text("This will delete your current timetable and reimport. Anyone you shared this timetable with will be able to access the updated one.")
				})
				.sheet(isPresented: $showCalendarImportSheet) {
					CalendarImportView()
						.presentationDetents([.fraction(1 / 3)])
						.presentationDragIndicator(.hidden)
				}

				Button {
					showEditTimetableSheet = true
				} label: {
					Label {
						Text("Edit")
					} icon: {
						Image(systemName: "pencil")
							.foregroundStyle(.tint)
					}
				}
				.disabled(!networkManager.isOnline)
				.matchedTransitionSource(id: "sheetMorph", in: ns)
				.sheet(isPresented: $showEditTimetableSheet) {
					SubjectEditorSheet(
						subjects: $subjects,
						initialRequest: nil,
						onSave: { proposedSubjects in
							try await ServerSyncCoordinator.shared.saveOwnerTimetable(proposedSubjects)
						}
					)
					.presentationDetents([.large])
					.presentationContentInteraction(.scrolls)
					.presentationDragIndicator(.hidden)
					.interactiveDismissDisabled()
					.navigationTransition(.zoom(sourceID: "sheetMorph", in: ns))
				}

				Toggle("Searchable", systemImage: "magnifyingglass", isOn: ownerVisibilityBinding)
					.disabled(!networkManager.isOnline)
			}

			Section("Preferences") {
				if sessionStore.isAuthenticated {
					NavigationLink {
						TagSubscriptionsView()
					} label: {
						Label("Event Tags", systemImage: "tag")
					}
				}

				if sessionStore.isAuthenticated {
					NavigationLink { AccountAndSyncSettingsView() } label: { Label("Updates & Notifications", systemImage: "switch.2") }
				} else {
					Button { showSignInRequired() } label: { Label("Updates", systemImage: "switch.2") }
				}

				Toggle("Highlight Current Day in timetables", systemImage: "inset.filled.lefthalf.righthalf.rectangle", isOn: highlightsCurrentDayBinding)

				Toggle("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right", isOn: hapticsBinding)
			}

			Section("Created Timetables") {
				if sessionStore.isAuthenticated {
					NavigationLink { CreatedTimetablesSettingsView() } label: { Label("Manage Created Timetables", systemImage: "person.2.crop.square.stack") }
				} else {
					Button { showSignInRequired() } label: { Label("Manage Created Timetables", systemImage: "person.2.crop.square.stack") }
				}
			}

			Section("Developer") {
				if _isDebugAssertConfiguration() || Defaults[.userDisplayName].contains("Adon") || Defaults[.calendarEvents].canManageGlobalEvents {
					LabeledContent {
						TextField("Seconds", value: $debugOffset, format: .number)
							.multilineTextAlignment(.trailing)
							.keyboardType(.numbersAndPunctuation)
					} label: {
						Label("Debug Offset", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
					}

					Button("Test progress badge", systemImage: "progress.indicator") {
						addDebugStatusBadge(title: "Syncing account", secondaryText: "Working", view: .progressView)
					}
					Button("Test success badge", systemImage: "checkmark.circle") {
						addDebugStatusBadge(title: "Saving timetable", view: .success)
					}
					Button("Test info badge", systemImage: "info.circle") {
						addDebugStatusBadge(title: "Info here", view: .info)
					}
					Button("Test error badge", systemImage: "xmark.circle") {
						addDebugStatusBadge(title: "Contacting server", view: .error)
					}
					Button("Test warning badge", systemImage: "exclamationmark.triangle") {
						addDebugStatusBadge(title: "Checking timetable", view: .warning)
					}
					Button("Test progress and gauge badge", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
						Task {
							let id = UUID()
							statusBadgeManager.addBadge(id: id, title: "Preparing timetable", priority: 3, view: .progressViewAndGauge(currentStep: 1, totalSteps: 3))

							try? await Task.sleep(for: .seconds(1))

							statusBadgeManager.updateBadge(id: id, title: "Preparing timetable", view: .progressViewAndGauge(currentStep: 2, totalSteps: 3))

							try? await Task.sleep(for: .seconds(1))

							statusBadgeManager.updateBadge(id: id, title: "Preparing timetable", view: .progressViewAndGauge(currentStep: 3, totalSteps: 3))

							try? await Task.sleep(for: .seconds(1))

							statusBadgeManager.updateBadge(id: id, title: "Prepared timetable", view: .success)
						}
					}
				}

				Button {
					guard sessionStore.isAuthenticated else {
						showSignInRequired()
						return
					}
					WidgetCenter.shared.reloadAllTimelines()
					statusBadgeManager.addBadge(id: UUID(), title: "Widgets reloaded", priority: 3, view: .success)
				} label: {
					Label("Reload widgets now", systemImage: "widget.large")
						.foregroundStyle(.accent)
				}
			}

			Section("Support") {
				Button {
					guard sessionStore.isAuthenticated else {
						showSignInRequired()
						return
					}
					showFeedbackSheet = true
				} label: {
					Label("Report Feedback or Bug", systemImage: "exclamationmark.bubble")
				}
				.matchedTransitionSource(id: "346361347", in: ns)
				.disabled(!networkManager.isOnline)
				.sheet(isPresented: $showFeedbackSheet) {
					FeedbackView()
						.presentationDetents([.fraction(0.7)])
						.navigationTransition(.zoom(sourceID: "346361347", in: ns))
				}

				NavigationLink {
					AboutView()
				} label: {
					Label("About Timetable", systemImage: "info.circle")
				}
				.listRowBackground(
					ColorfulView(
						color: $colors,
						speed: $speed,
						bias: .constant(0.00001),
						noise: .constant(64),
						transitionSpeed: $colorTransitionSpeed,
						frameLimit: .constant(60),
						renderScale: .constant(1)
					)
				)

				Label {
					Text("Last Server Sync")

					Text(lastServerSync?.formatted(date: .complete, time: .complete) ?? "Never")
						.foregroundStyle(.secondary)
				} icon: {
					Image(systemName: "checkmark.icloud")
				}

				Label {
					HStack {
						Text("\(Bundle.main.appVersion)")
						Text("(\(Bundle.main.buildNumber))")
							.foregroundStyle(.secondary)
					}
				} icon: {
					Image(systemName: "hammer")
				}
			}
		}

		@Default(.hapticsEnabled) private var hapticsEnabled

		private var highlightsCurrentDayBinding: Binding<Bool> {
			Binding(
				get: { settings.highlightsCurrentDay },
				set: { value in
					settingsSaveGeneration += 1
					let generation = settingsSaveGeneration
					let previous = committedSettings
					settings.highlightsCurrentDay = value
					let proposed = settings
					Task {
						do {
							try await settingsSync.updateSettings(proposed)
							guard generation == settingsSaveGeneration else { return }
							committedSettings = proposed
						} catch {
							guard generation == settingsSaveGeneration else { return }
							settings = previous
							statusBadgeManager.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
						}
					}
				}
			)
		}

		private var hapticsBinding: Binding<Bool> {
			Binding(get: { hapticsEnabled }, set: { hapticsEnabled = $0 })
		}

		private var ownerVisibilityBinding: Binding<Bool> {
			Binding(
				get: { ownerIsSearchable },
				set: { value in
					guard sessionStore.isAuthenticated else {
						ownerIsSearchable = committedOwnerIsSearchable
						showSignInRequired()
						return
					}

					visibilitySaveGeneration += 1
					let generation = visibilitySaveGeneration
					let previous = committedOwnerIsSearchable
					ownerIsSearchable = value
					Task { await saveOwnerVisibility(value, previous: previous, generation: generation) }
				}
			)
		}

		private func saveOwnerVisibility(_ proposed: Bool, previous: Bool, generation: Int) async {
			do {
				let committed = try await OwnerTimetableSyncService.shared.updateVisibility(proposed)
				guard generation == visibilitySaveGeneration else { return }
				ownerIsSearchable = committed
				committedOwnerIsSearchable = committed
			} catch {
				guard generation == visibilitySaveGeneration else { return }
				ownerIsSearchable = previous
				statusBadgeManager.addBadge(id: UUID(), title: "Unable to update visibility", secondaryText: error.localizedDescription, priority: 4, view: .error)
			}
		}

		private func addDebugStatusBadge(title: String, secondaryText: String? = nil, view: StatusBadgeView) {
			let id = UUID()
			statusBadgeManager.addBadge(id: id, title: title, secondaryText: secondaryText, priority: 3, view: view)

			Task {
				try? await Task.sleep(for: .seconds(4))
				statusBadgeManager.updateBadge(id: id, title: "Done", view: .success)
			}
		}

		private func showSignInRequired() {
			statusBadgeManager.signInRequired()
		}
	}

#endif // os(iOS)
