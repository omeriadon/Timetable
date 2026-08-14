//
//   SettingsView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import ColorfulX
import Defaults
import GlurBackdrop
import SwiftUI
import TipKit
import UIKit
import WidgetKit

struct SettingsView: View {
	@Default(.timetable) var subjects
	@Default(.lastServerSync) var lastServerSync
	@Default(.userDisplayName) var userDisplayName
	@Default(.accountProfile) private var accountProfile

	@Environment(\.statusBadgeManager) private var statusBadgeManager
	@State private var sessionStore = SessionStore.shared
	@State private var networkManager = NetworkManager.shared
	@State private var settings = Defaults[.accountSettings]
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var settingsSync = AccountSettingsSyncService.shared
	@State private var settingsSaveGeneration = 0
	@State private var liveActivityDebugState: LiveActivityDebugStateResponse?
	@Default(.debugOffset) private var debugOffset

	@State private var showCalendarImportSheet = false
	@State private var showEditTimetableSheet = false
	@State private var showFeedbackSheet = false
	@State private var showImportConfirmation = false
	#if DEBUG
		@State private var usesReleaseAppIcon = UIApplication.shared.alternateIconName == "Timetable"
	#endif

	@State private var colors = [
		Color.brown,
		Color(uiColor: .clear),
		Color(uiColor: .clear),
		Color(uiColor: .clear),
		Color(uiColor: .clear),
	]
	@State private var speed = 0.6
	@State private var colorTransitionSpeed = 10.0

	var body: some View {
		List { list }
			.minimizingToolbarOnScrollDown()
			.listStyle(.sidebar)
			.scrollEdgeEffect(offset: 0.9, maxBlurRadius: 1, maximumOpacity: 0.3)
			.scrollEdgeEffectStyle(.soft, for: .top)
			.appPaperBackground()
			.appNavigationTitle("Settings", style: .main, accent: true)
			.task(id: sessionStore.isAuthenticated) {
				await refreshLiveActivityDebugState()
			}
	}

	private var accountBackground: some View {
		AccountBackgroundView(profile: Defaults[.accountProfile])
			.clipShape(Capsule())
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
						.foregroundStyle(
							accountProfile?.appearance.foregroundColour.swiftUIColor
								?? ProfileAppearance.default.foregroundColour.swiftUIColor
						)
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
				Text("This will delete your current timetable and reimport it from Calendar.")
			})
			.sheet(isPresented: $showCalendarImportSheet) {
				CalendarImportView()
					.presentationDetents([.fraction(1 / 3)])
					.presentationDragIndicator(.hidden)
					.appPaperPresentation()
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
			.sheet(isPresented: $showEditTimetableSheet) {
				SubjectEditorSheet(
					close: { showEditTimetableSheet = false },
					subjects: $subjects,
					initialRequest: nil,
					onSave: { proposedSubjects in
						try await ServerSyncCoordinator.shared.saveOwnerTimetable(proposedSubjects)
					}
				)
				.presentationDetents([.large])
				.presentationContentInteraction(.scrolls)
				.presentationDragIndicator(.hidden)
				.appPaperPresentation()
			}
		}
		.glurListRowBackground()

		Section("Preferences") {
			if sessionStore.isAuthenticated {
				NavigationLink {
					AppearanceSettingsView()
				} label: {
					Label("Appearance", systemImage: "paintpalette")
				}
			}

			if sessionStore.isAuthenticated {
				NavigationLink { AccountAndSyncSettingsView() } label: { Label("Updates & Notifications", systemImage: "switch.2") }

				Picker("Show Future Events", systemImage: "calendar.badge.clock", selection: futureEventRangeBinding) {
					ForEach(FutureEventRange.allCases) { range in
						Text(range.title)
							.tag(range)
					}
				}
			} else {
				Button { showSignInRequired() } label: { Label("Updates", systemImage: "switch.2") }
			}

			NavigationLink {
				ArchivedEventsView()
			} label: {
				Label("Archived Events", systemImage: "archivebox")
			}
		}
		.glurListRowBackground()

		Section("Developer") {
			#if DEBUG
				Toggle("Release App Icon", systemImage: "app.badge", isOn: $usesReleaseAppIcon)
					.disabled(!UIApplication.shared.supportsAlternateIcons)
					.onChange(of: usesReleaseAppIcon) { oldValue, newValue in
						changeAppIcon(useReleaseIcon: newValue, previousValue: oldValue)
					}
			#endif // DEBUG

			if canUseDeveloperTools {
				LabeledContent {
					TextField("Seconds", value: $debugOffset, format: .number)
						.multilineTextAlignment(.trailing)
						.keyboardType(.numbersAndPunctuation)
				} label: {
					Label("Debug Offset", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
				}

				liveActivityDebugMenu

				Menu {
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
						runDebugGaugeBadge()
					}
				} label: {
					Label("Test status badges", systemImage: "app.badge")
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

			Button {
				try? Tips.resetDatastore()
				statusBadgeManager.addBadge(
					id: UUID(),
					title: "Tips Reset",
					secondaryText: "Restart app to see effects.",
					priority: 3,
					view: .success
				)
			} label: {
				Label("Reset Tips", systemImage: "lightbulb")
			}

			Label {
				Text("Last Server Sync")

				Text(lastServerSync?.formatted(date: .complete, time: .complete) ?? "Never")
					.foregroundStyle(.secondary)
			} icon: {
				Image(systemName: "checkmark.icloud")
			}
		}
		.glurListRowBackground()

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
			.disabled(!networkManager.isOnline)
			.sheet(isPresented: $showFeedbackSheet) {
				FeedbackView(close: { showFeedbackSheet = false })
					.presentationDetents([.fraction(0.7)])
					.appPaperPresentation()
			}

			NavigationLink {
				AboutView()
			} label: {
				Label("About Timetable", systemImage: "info.circle")
			}
			.listRowBackground(
				ZStack {
					GlurView(radius: 3, offset: 0, interpolation: 0)

					ColorfulView(
						color: $colors,
						speed: $speed,
						bias: .constant(0.00001),
						noise: .constant(64),
						transitionSpeed: $colorTransitionSpeed,
						frameLimit: .constant(60),
						renderScale: .constant(1)
					)
				}
			)

			Button {
				UIPasteboard.general.string = versionAndBuild
				statusBadgeManager.addBadge(id: UUID(), title: "Copied", priority: 3, view: .success)
			} label: {
				Label {
					Text(Bundle.main.appVersion)
					Text("(\(Bundle.main.buildNumber))")
						.foregroundStyle(.secondary)

				} icon: {
					Image(systemName: "hammer")
						.foregroundStyle(.accent)
				}
			}
		}
		.glurListRowBackground()
	}

	private var futureEventRangeBinding: Binding<FutureEventRange> {
		Binding(
			get: { settings.futureEventRange },
			set: { value in
				settingsSaveGeneration += 1
				let generation = settingsSaveGeneration
				let previous = committedSettings
				settings.futureEventRange = value
				let proposed = settings
				Task {
					do {
						try await settingsSync.updateSettings(proposed)
						guard generation == settingsSaveGeneration else { return }
						committedSettings = proposed
					} catch {
						guard generation == settingsSaveGeneration else { return }
						settings = previous
						statusBadgeManager.addBadge(
							id: UUID(),
							title: "Unable to save preferences",
							secondaryText: error.localizedDescription,
							priority: 4,
							view: .error
						)
					}
				}
			}
		)
	}

	private func addDebugStatusBadge(title: String, secondaryText: String? = nil, view: StatusBadgeView) {
		let id = UUID()
		statusBadgeManager.addBadge(id: id, title: title, secondaryText: secondaryText, priority: 3, view: view)

		Task {
			try? await Task.sleep(for: .seconds(4))
			statusBadgeManager.updateBadge(id: id, title: "Done", view: .success)
		}
	}

	@ViewBuilder
	private var liveActivityDebugMenu: some View {
		if let liveActivityDebugState,
		   !liveActivityDebugState.isActive || liveActivityDebugState.canUpdate
		{
			Menu {
				if !liveActivityDebugState.isActive {
					Button("Start", systemImage: "play.fill") {
						performLiveActivityDebugAction {
							try await LiveActivityRegistrationService.shared.startDebugActivity()
						}
					}
				} else if liveActivityDebugState.canUpdate {
					Button("Stop", systemImage: "stop.fill", role: .destructive) {
						performLiveActivityDebugAction {
							try await LiveActivityRegistrationService.shared.stopDebugActivity()
						}
					}

					Divider()

					ForEach(DebugTransition.allCases, id: \.self) { transition in
						Button("Update to \(transition.title)", systemImage: transition.symbol) {
							performLiveActivityDebugAction {
								try await LiveActivityRegistrationService.shared.updateDebugActivity(to: transition)
							}
						}
					}
				}
			} label: {
				Label("Test Live Activity", systemImage: "rectangle.bottomthird.inset.filled")
			}
		}
	}

	private var canUseDeveloperTools: Bool {
		_isDebugAssertConfiguration()
			|| Defaults[.userDisplayName].contains("Adon")
			|| Defaults[.calendarEvents].canManageGlobalEvents
	}

	private func refreshLiveActivityDebugState() async {
		guard canUseDeveloperTools, sessionStore.isAuthenticated else {
			liveActivityDebugState = nil
			return
		}

		do {
			liveActivityDebugState = try await LiveActivityRegistrationService.shared.debugState()
		} catch {
			liveActivityDebugState = nil
		}
	}

	private func performLiveActivityDebugAction(
		_ action: @escaping @MainActor () async throws -> LiveActivityDebugStateResponse
	) {
		Task {
			do {
				liveActivityDebugState = try await action()
				try? await Task.sleep(for: .seconds(2))
				await refreshLiveActivityDebugState()
			} catch {
				statusBadgeManager.addBadge(
					id: UUID(),
					title: "Live Activity Test Failed",
					secondaryText: error.localizedDescription,
					priority: 4,
					view: .error
				)
			}
		}
	}

	private func runDebugGaugeBadge() {
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

	private var versionAndBuild: String {
		"\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
	}

	#if DEBUG
		private func changeAppIcon(useReleaseIcon: Bool, previousValue: Bool) {
			Task {
				do {
					try await UIApplication.shared.setAlternateIconName(useReleaseIcon ? "Timetable" : nil)
				} catch {
					usesReleaseAppIcon = previousValue
					statusBadgeManager.addBadge(
						id: UUID(),
						title: "Unable to Change App Icon",
						secondaryText: error.localizedDescription,
						priority: 4,
						view: .error
					)
				}
			}
		}
	#endif

	private func showSignInRequired() {
		statusBadgeManager.signInRequired()
	}
}
