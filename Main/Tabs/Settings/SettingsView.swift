//
//   SettingsView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

#if os(iOS)

	struct RenameTimetable: Identifiable {
		let id: String
		let timetable: ReceivedTimetable
	}

	struct SettingsView: View {
		@Default(.timetable) var subjects
		@Default(.receivedTimetables) private var receivedTimetables

		@Environment(\.statusBadgeManager) private var statusBadgeManager
		@State private var sessionStore = SessionStore.shared
		@State private var networkManager = NetworkManager.shared
		@State private var settings = Defaults[.accountSettings]
		@State private var committedSettings = Defaults[.accountSettings]
		@State private var settingsSync = AccountSettingsSyncService.shared
		@State private var settingsSaveGeneration = 0

		let watchSync: PhoneWatchSyncBridge

		@Binding var syncStatus: SyncMode

		@State private var showCalendarImportSheet = false
		@State private var showEditTimetableSheet = false
		@State private var ownerIsSearchable = Defaults[.ownerIsSearchable]
		@State private var committedOwnerIsSearchable = Defaults[.ownerIsSearchable]
		@State private var visibilitySaveGeneration = 0
		@State private var showEditReceivedTimetablesSheet = false
		@State private var showFeedbackSheet = false

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
				.scrollEdgeEffectStyle(.soft, for: .top)
				.scrollContentBackground(.hidden)
				.appNavigationTitle("Settings", style: .main)
			}
		}

		@ContentBuilder
		private var list: some View {
			Section("Account") {
				NavigationLink {
					AccountView()
				} label: {
					Label("Account", systemImage: "person.crop.circle")
				}
			}

			Section("Preferences") {
				Toggle("Highlight Current Day in timetables", isOn: highlightsCurrentDayBinding)
				if sessionStore.isAuthenticated {
					NavigationLink { AccountAndSyncSettingsView() } label: { Label("Live Updates", systemImage: "switch.2") }
				} else {
					Button { showSignInRequired() } label: { Label("Live Updates", systemImage: "switch.2") }
				}
				Toggle("Haptic Feedback", isOn: hapticsBinding)
			}

			Section("Your Timetable") {
				Toggle("Searchable", isOn: ownerVisibilityBinding)
					.disabled(!networkManager.isOnline)
				Button {
					showEditTimetableSheet = true
				} label: {
					Label {
						Text("Edit Timetable")
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
			}

			Section("Authored Timetables") {
				if sessionStore.isAuthenticated {
					NavigationLink { AuthoredTimetablesSettingsView() } label: { Label("Manage Authored Timetables", systemImage: "person.2.crop.square.stack") }
				} else {
					Button { showSignInRequired() } label: { Label("Manage Authored Timetables", systemImage: "person.2.crop.square.stack") }
				}
			}

			Section("Calendar") {
				Button {
					showCalendarImportSheet = true
				} label: {
					HStack(alignment: .center) {
						Image(systemName: "calendar")
							.foregroundStyle(.tint)
							.imageScale(.large)
							.padding(.trailing, 10)

						VStack(alignment: .leading) {
							Text("Import from Calendar")
								.foregroundStyle(.accent)
							Text("Subscribe to Compass Schedule in Calendar")
								.foregroundStyle(.secondary)
								.font(.callout)
						}
					}
				}
				.sheet(isPresented: $showCalendarImportSheet) {
					CalendarImportView()
						.presentationDetents([.fraction(1 / 3)])
						.presentationDragIndicator(.hidden)
				}
			}

			if receivedTimetables.contains(where: { !$0.isDeleted }) {
				Section("Imported Timetables") {
					Button {
						if sessionStore.isAuthenticated {
							showEditReceivedTimetablesSheet = true
						} else {
							showSignInRequired()
						}
					} label: {
						Label("Edit Received Timetables...", systemImage: "calendar")
					}
					.matchedTransitionSource(id: "unique_transition_id", in: ns)
					.sheet(isPresented: $showEditReceivedTimetablesSheet) {
						ReceivedTimetablesView()
							.presentationDetents([.fraction(0.8)])
							.presentationDragIndicator(.hidden)
							.navigationTransition(
								.zoom(sourceID: "unique_transition_id", in: ns)
							)
					}
					.onChange(of: receivedTimetables) { _, newValue in
						if newValue.isEmpty {}
					}
				}
			}
			Section("Developer") {
				if _isDebugAssertConfiguration() || Defaults[.userDisplayName].contains("Adon") {
					NavigationLink("Live Activity Debug") {
						LiveActivityDebugView()
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

					Button("reset onboarding") {
						Defaults[.hasCompletedOnboarding] = false
						Defaults[.hasSeenOnboardingBefore] = false
						Defaults[.onboardingPageID] = ""
					}
				}

				Button {
					guard sessionStore.isAuthenticated else { showSignInRequired(); return }
					WidgetCenter.shared.reloadAllTimelines()
					statusBadgeManager.addBadge(id: UUID(), title: "Widgets reloaded", priority: 3, view: .success)
				} label: {
					Label("Reload widgets now", systemImage: "widget.large")
						.foregroundStyle(.accent)
				}
			}

			Section("Support") {
				Button {
					guard sessionStore.isAuthenticated else { showSignInRequired(); return }
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

				HStack {
					Text("\(Bundle.main.appVersion)")
					Text("(\(Bundle.main.buildNumber))")
						.foregroundStyle(.secondary)
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
							statusBadgeManager.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
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
				statusBadgeManager.addBadge(id: UUID(), title: "Visibility updated", priority: 3, view: .success)
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
