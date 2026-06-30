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
	@State private var testResult: String?

	var body: some View {
		Form {
			Section("Account Settings") {
				Toggle("Live Activities", isOn: $settings.liveActivitiesEnabled)
				Toggle("Allow Notifications", isOn: $settings.notificationsEnabled)

				#if os(iOS) || os(visionOS)
					Button("Send Test Notification", systemImage: "bell.badge") {
						Task {
							do {
								let count = try await NotificationRegistrationService.shared.sendTestNotification()
								testResult = count == 1 ? "Sent to 1 device." : "Sent to \(count) devices."
							} catch {
								testResult = error.localizedDescription
							}
						}
					}
					.disabled(!settings.notificationsEnabled)

					if let testResult {
						Text(testResult)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				#endif
			}
		}
		.appNavigationTitle("Account and Sync")
		.onChange(of: settings) { oldValue, newValue in
			guard oldValue != newValue else { return }
			Task {
				do {
					try await settingsSync.updateSettings(newValue)
					#if os(iOS) || os(visionOS)
						if oldValue.notificationsEnabled != newValue.notificationsEnabled {
							let enabled = await NotificationRegistrationService.shared.reconcile(
								enabled: newValue.notificationsEnabled
							)
							if newValue.notificationsEnabled, !enabled {
								var disabledSettings = newValue
								disabledSettings.notificationsEnabled = false
								settings = disabledSettings
								try await settingsSync.updateSettings(disabledSettings)
							}
						}
					#endif
				} catch {
					settings = Defaults[.accountSettings]
				}
			}
		}
	}
}
