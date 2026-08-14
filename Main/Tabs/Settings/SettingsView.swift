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
	@Default(.debugOffset) private var debugOffset

	@State private var showCalendarImportSheet = false
	@State private var showEditTimetableSheet = false
	@State private var showFeedbackSheet = false
	@State private var showImportConfirmation = false

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
	}

	private var accountBackground: some View {
		AccountBackgroundView(profile: Defaults[.accountProfile])
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

				Picker("Future Events", systemImage: "calendar.badge.clock", selection: futureEventRangeBinding) {
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
				HStack {
					Image(systemName: "hammer")
					Text(Bundle.main.appVersion)
					Text("(\(Bundle.main.buildNumber))")
						.foregroundStyle(.secondary)
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

	private var versionAndBuild: String {
		"\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
	}

	private func showSignInRequired() {
		statusBadgeManager.signInRequired()
	}
}
