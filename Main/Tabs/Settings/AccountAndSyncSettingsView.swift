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
	@State private var networkManager = NetworkManager.shared
	@State private var settingsSync = AccountSettingsSyncService.shared

	@State private var notificationRegistration = NotificationRegistrationService.shared

	@State private var testResult: String?
	@Environment(\.statusBadgeManager) private var badges
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var saveGeneration = 0

	var body: some View {
		Form {
			Toggle(isOn: preferenceBinding(\.liveActivitiesEnabled)) {
				Text("Live Activities")
				Text("Show live countdowns and details for your subjects and breaks throughout the school day, including on your Watch.")
			}

			Section {
				Toggle(isOn: preferenceBinding(\.notificationsEnabled)) {
					Text("Allow Class Notifications")
					Text("Send notifications for each class throughout the day.")
				}

				VStack {
					Text("Send Notifications Early By...")
					Picker("Send Notiications Early By...", selection: leadTimeBinding) {
						ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
							Text("\(leadTime.minutes) \(leadTime.minutes == 1 ? "minute " : "minutes")")
								.tag(leadTime)
						}
					}
					#if os(iOS)
					.pickerStyle(.wheel)
					#else
					.pickerStyle(.radioGroup)
					#endif
					.disabled(!settings.notificationsEnabled)
				}
				.opacity(settings.broadcastNotificationsEnabled ? 1 : 0.3)

				#if os(iOS)
					Button {
						Task {
							do {
								let count = try await notificationRegistration.sendTestNotification()
								testResult = count == 1 ? "Sent to 1 device." : "Sent to \(count) devices."
							} catch {
								testResult = error.localizedDescription
							}
						}
					} label: {
						VStack(alignment: .leading) {
							Label("Send Test Notification", systemImage: "bell.badge")
							switch notificationRegistration.registrationState {
								case let .failed(message):
									Text(message).foregroundStyle(.red.secondary)
								case .registering:
									Text("Registering this device…").foregroundStyle(.secondary)
								case .idle, .tokenReceived:
									Text("Sign in and wait for device registration to finish.").foregroundStyle(.secondary)
								case .registered:
									EmptyView()
							}
						}
						.font(.callout)
					}
					.disabled(!settings.notificationsEnabled || notificationRegistration.registrationState != .registered)
					.onChange(of: testResult) {
						if let testResult {
							if testResult == "Sent to 0 devices." {
								badges.addBadge(id: UUID(), title: testResult, priority: 4, view: .error)
							} else if testResult.contains("devices") || testResult == "Sent to 1 device." {
								badges.addBadge(id: UUID(), title: testResult, priority: 4, view: .success)
							} else {
								badges.addBadge(id: UUID(), title: testResult, priority: 4, view: .error)
							}
						}
					}
				#endif // os(iOS)
			}

			Section {
				Toggle(isOn: preferenceBinding(\.broadcastNotificationsEnabled)) {
					Text("Special Event Notifications")
					Text("Special Event Notifications include announcements and limited-time events, such as special school events.")
				}
			}
		}
		.disabled(!networkManager.isOnline)
		.overlay {
			if !networkManager.isOnline {
				ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text("Account preferences are unavailable until a connection is restored."))
			}
		}
		.animation(.easeInOut, value: notificationRegistration.registrationState)
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
			try await settingsSync.updateSettings(proposed)
			guard generation == saveGeneration else { return }
			committedSettings = proposed
			badges.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
		} catch {
			guard generation == saveGeneration else { return }
			settings = previous
			badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}
