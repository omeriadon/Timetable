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
			Section("Account Settings") {
				Toggle("Live Activities", isOn: preferenceBinding(\.liveActivitiesEnabled))
				Toggle("Allow Notifications", isOn: preferenceBinding(\.notificationsEnabled))
				Picker("Notification Advance", selection: leadTimeBinding) {
					ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
						Text("\(leadTime.minutes) \(leadTime.minutes == 1 ? "minute" : "minutes")")
							.tag(leadTime)
					}
				}
				.pickerStyle(.wheel)
				.disabled(!settings.notificationsEnabled)

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

					if settings.notificationsEnabled, notificationRegistration.registrationState == .registering {
						Text("Registering this device…")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}

					if settings.notificationsEnabled, notificationRegistration.registrationState == .failed {
						Text("Device notification registration failed.")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}

					if let testResult {
						Text(testResult)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				#endif
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
				if !previous.notificationsEnabled, proposed.notificationsEnabled {
					guard await NotificationRegistrationService.shared.reconcile(enabled: true) else {
						if generation == saveGeneration { settings = previous }
						return
					}
				}
			#endif
			try await settingsSync.updateSettings(proposed)
			#if os(iOS)
				if previous.notificationsEnabled, !proposed.notificationsEnabled {
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
}
