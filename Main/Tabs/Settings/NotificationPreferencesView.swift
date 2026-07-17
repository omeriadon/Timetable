import Defaults
import SwiftUI

struct NotificationPreferencesView: View {
	@Default(.accountSettings) private var settings

	var body: some View {
		Form {
			Section {
				Toggle("Allow Class Notifications", isOn: localBinding(\.notificationsEnabled))
				Picker("Send Notifications Early By...", selection: localBinding(\.notificationLeadTime)) {
					ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
						Text("\(leadTime.minutes) \(leadTime.minutes == 1 ? "minute" : "minutes")").tag(leadTime)
					}
				}
				.disabled(!settings.notificationsEnabled)
			}
			Section { Toggle("Special Event Notifications", isOn: localBinding(\.broadcastNotificationsEnabled)) }
		}
		.appNavigationTitle("Notifications")
	}

	private func localBinding<Value>(_ keyPath: WritableKeyPath<AccountSettings, Value>) -> Binding<Value> {
		Binding(get: { settings[keyPath: keyPath] }, set: { value in
			var updated = settings
			updated[keyPath: keyPath] = value
			settings = updated
		})
	}
}
