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
	@Environment(\.statusBadgeManager) private var badges
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var saveGeneration = 0

	var body: some View {
		Form {
			Section("Account Settings") {
				Toggle("Live Activities", isOn: preferenceBinding(\.liveActivitiesEnabled))
				Toggle("Allow Notifications", isOn: preferenceBinding(\.notificationsEnabled))

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

	private func save(_ proposed: AccountSettings, previous: AccountSettings, generation: Int) async {
		do {
			#if os(iOS) || os(visionOS)
				if !previous.notificationsEnabled, proposed.notificationsEnabled {
					guard await NotificationRegistrationService.shared.reconcile(enabled: true) else {
						if generation == saveGeneration { settings = previous }
						return
					}
				}
			#endif
			try await settingsSync.updateSettings(proposed)
			#if os(iOS) || os(visionOS)
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
