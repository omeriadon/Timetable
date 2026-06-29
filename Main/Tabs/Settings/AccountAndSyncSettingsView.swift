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

	var body: some View {
		Form {
			Section("Account Settings") {
				Toggle("Live Activities", isOn: $settings.liveActivitiesEnabled)
				Toggle("Allow Notifications", isOn: $settings.notificationsEnabled)
			}
		}
		.navigationTitle("Account and Sync")
		.onChange(of: settings) { oldValue, newValue in
			guard oldValue != newValue else { return }
			Task {
				do {
					try await settingsSync.updateSettings(newValue)
				} catch {
					settings = Defaults[.accountSettings]
				}
			}
		}
	}
}
