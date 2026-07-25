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

				NotificationLeadTimesEditor(selection: localBinding(\.notificationLeadTimes))
					.disabled(!settings.notificationsEnabled)

				BreakToPeriodNotificationLeadTimesEditor(selection: localBinding(\.breakToPeriodNotificationLeadTimes))
					.disabled(!settings.notificationsEnabled)
			}

			Section {
				Toggle("Special Event Notifications", isOn: localBinding(\.broadcastNotificationsEnabled))
			}

			Section("Event Notifications") {
				EventNotificationSchedulesEditor(selection: localBinding(\.eventNotificationSchedules))
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
				} catch {
					settings = previous
					badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
				}
			}
		})
	}
}
