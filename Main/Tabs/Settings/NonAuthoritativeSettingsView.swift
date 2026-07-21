import Defaults
import SwiftUI
import WidgetKit

struct NonAuthoritativeSettingsView: View {
	@Environment(\.statusBadgeManager) private var statusBadgeManager
	@State private var sessionStore = SessionStore.shared
	@State private var networkManager = NetworkManager.shared
	@State private var settings = Defaults[.accountSettings]
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var settingsSync = AccountSettingsSyncService.shared
	@State private var saveGeneration = 0
	@State private var showFeedbackSheet = false

	@Binding var expanded: WindowMode

	init(expanded: Binding<WindowMode>) {
		_expanded = expanded
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Account") {
					NavigationLink {
						NonAuthoritativeAccountView()
					} label: {
						Label("Account", systemImage: "person.crop.circle")
					}
				}

				Section("Preferences") {
					NavigationLink {
						NotificationPreferencesView()
					} label: {
						Label("Notifications", systemImage: "bell")
					}

					Toggle("Highlight Current Day in timetables", isOn: highlightsBinding)
				}

				Section {
					Button("Sign Out", systemImage: "door.left.hand.open", role: .destructive) {
						Task {
							await SessionStore.shared.signOut()
						}
					}
					.foregroundStyle(.red)
				}

				Section("Developer") {
					if _isDebugAssertConfiguration() || Defaults[.userDisplayName].contains("Adon") {
						#if os(iOS)
							NavigationLink("Live Activity Debug") {
								LiveActivityDebugView()
							}
						#endif

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
					.disabled(!networkManager.isOnline)
					.sheet(isPresented: $showFeedbackSheet) {
						FeedbackView()
						#if os(macOS)
							.frame(width: 640)
						#endif
					}

					HStack {
						Text("\(Bundle.main.appVersion)")
						Text("(\(Bundle.main.buildNumber))")
							.foregroundStyle(.secondary)
					}
				}
			}
			.scrollContentBackground(.hidden)
			.formStyle(.grouped)
			.appNavigationTitle("Settings", style: .main)
		}
		#if os(macOS)
		.onAppear { expanded = .settings }
		.onDisappear { expanded = .none }
		#endif
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

	private var highlightsBinding: Binding<Bool> {
		Binding(
			get: { settings.highlightsCurrentDay },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings.highlightsCurrentDay = value
				let proposed = settings
				Task {
					do {
						try await settingsSync.updateSettings(proposed)
						guard generation == saveGeneration else { return }
						committedSettings = proposed
						statusBadgeManager.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
					} catch {
						guard generation == saveGeneration else { return }
						settings = previous
						statusBadgeManager.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
					}
				}
			}
		)
	}
}
