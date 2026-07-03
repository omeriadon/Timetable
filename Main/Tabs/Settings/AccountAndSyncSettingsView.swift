//
//   AccountAndSyncSettingsView.swift
//   Main
//
//   Created by Codex on 29/6/2026.
//

import Defaults
import SwiftUI

struct AccountAndSyncSettingsView: View {
	@State private var settings = Defaults[.accountSettings]
	@State private var settingsSync = AccountSettingsSyncService.shared
	#if os(iOS)
		@State private var notificationRegistration = NotificationRegistrationService.shared
	#endif
	@State private var testResult: String?
	@Environment(\.statusBadgeManager) private var badges
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var saveGeneration = 0

	var body: some View {
		Form {
			Toggle(isOn: preferenceBinding(\.liveActivitiesEnabled)) {
				Text("Live Activities")
				Text("Show live countdowns and details throughout the day, including on your Watch.")
			}

			Section {
				Toggle(isOn: preferenceBinding(\.notificationsEnabled)) {
					Text("Allow Class Notifications")
					Text("Send notifications for each class.")
				}

				#if os(iOS)
					Button("Send Test Notification", systemImage: "bell.badge") {
						Task {
							do {
								let count = try await notificationRegistration.sendTestNotification()
								testResult = count == 1 ? "Sent to 1 device." : "Sent to \(count) devices."
							} catch {
								testResult = error.localizedDescription
							}
						}
					}
					.disabled(!settings.notificationsEnabled || notificationRegistration.registrationState != .registered)
					.onChange(of: "\(notificationsRequired)\(notificationRegistration.registrationState)") {
						if notificationsRequired, notificationRegistration.registrationState == .registering {
							StatusBadgeManager().addBadge(id: UUID(), title: "Registering this device…", priority: 5, view: .progressView)
						}

						if notificationsRequired, notificationRegistration.registrationState == .failed {
							StatusBadgeManager().addBadge(id: UUID(), title: "Device notification registration failed.", priority: 5, view: .error)
						}
					}
					.onChange(of: testResult) {
						if let testResult {
							if testResult == "Sent to 0 devices." {
								StatusBadgeManager().addBadge(id: UUID(), title: testResult, priority: 4, view: .error)
							} else if testResult.contains("devices") || testResult == "Sent to 1 device." {
								StatusBadgeManager().addBadge(id: UUID(), title: testResult, priority: 4, view: .success)
							} else {
								StatusBadgeManager().addBadge(id: UUID(), title: testResult, priority: 4, view: .error)
							}
						}
					}
				#endif // os(iOS)
			}

			Section {
				Toggle(isOn: preferenceBinding(\.broadcastNotificationsEnabled)) {
					Text("Special Event Notifications")
					Text("Special Event Notifications include announcements and limited-time events. This preference is independent from timetable notifications.")
				}

				VStack {
					Text("Send Notifications Early By...")
					Picker("Send Notiications Early By...", selection: leadTimeBinding) {
						ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
							Text("\(leadTime.minutes) \(leadTime.minutes == 1 ? "minute " : "minutes")")
								.tag(leadTime)
						}
					}
					.pickerStyle(.wheel)
					.disabled(!settings.broadcastNotificationsEnabled)
				}
				.opacity(settings.broadcastNotificationsEnabled ? 1 : 0.5)
			}
		}
		.appNavigationTitle("Preferences")
	}

	private func preferenceBinding(_ keyPath: WritableKeyPath<AccountSettings, Bool>) -> Binding<Bool> {
		Binding(
			get: { settings[keyPath: keyPath] },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings[keyPath: keyPath] = value
				let proposed = settings
				Task { await save(proposed, previous: previous, generation: generation) }
			}
		)
	}

	private var leadTimeBinding: Binding<NotificationLeadTime> {
		Binding(
			get: { settings.notificationLeadTime },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings.notificationLeadTime = value
				let proposed = settings
				Task { await save(proposed, previous: previous, generation: generation) }
			}
		)
	}

	private func save(_ proposed: AccountSettings, previous: AccountSettings, generation: Int) async {
		do {
			#if os(iOS)
				let previouslyRequired = previous.notificationsEnabled || previous.broadcastNotificationsEnabled
				let proposedRequired = proposed.notificationsEnabled || proposed.broadcastNotificationsEnabled
				if !previouslyRequired, proposedRequired {
					guard await NotificationRegistrationService.shared.reconcile(enabled: true) else {
						if generation == saveGeneration { settings = previous }
						return
					}
				}
			#endif
			try await settingsSync.updateSettings(proposed)
			#if os(iOS)
				if previouslyRequired, !proposedRequired {
					_ = await NotificationRegistrationService.shared.reconcile(enabled: false)
				}
			#endif
			guard generation == saveGeneration else { return }
			committedSettings = proposed
			badges.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
		} catch {
			guard generation == saveGeneration else { return }
			settings = previous
			badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}

	private var notificationsRequired: Bool {
		settings.notificationsEnabled || settings.broadcastNotificationsEnabled
	}
}
