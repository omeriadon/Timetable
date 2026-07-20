import Defaults
import SwiftUI

struct NotificationPreferencesView: View {
	@Default(.accountSettings) private var settings
	@State private var settingsSync = AccountSettingsSyncService.shared
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		Form {
			Section {
				Toggle("Allow Class Notifications", isOn: localBinding(\.notificationsEnabled))

				Picker("Send Notifications Early By...", selection: localBinding(\.notificationLeadTime)) {
					ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
						Text("\(leadTime.minutes) \(leadTime.minutes == 1 ? "minute" : "minutes")").tag(leadTime)
					}
				}
				#if os(macOS)
				.pickerStyle(.radioGroup)
				#endif
				.disabled(!settings.notificationsEnabled)
			}

			Section {
				Toggle("Special Event Notifications", isOn: localBinding(\.broadcastNotificationsEnabled))
			}
		}
		.formStyle(.grouped)
		.scrollContentBackground(.hidden)
		.appNavigationTitle("Notifications")
	}

	private func localBinding<Value>(_ keyPath: WritableKeyPath<AccountSettings, Value>) -> Binding<Value> {
		Binding(get: { settings[keyPath: keyPath] }, set: { value in
			let previous = settings
			var updated = settings
			updated[keyPath: keyPath] = value
			settings = updated
			Task { @MainActor in
				do {
					settings = try await settingsSync.updateNotificationSettings(updated)
					badges.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
				} catch {
					settings = previous
					badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
				}
			}
		})
	}
}
