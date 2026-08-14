import Foundation
import WatchKit

@MainActor
final class WatchExtensionDelegate: NSObject, WKExtensionDelegate {
	func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
		Task {
			await WatchNotificationRegistrationService.shared.receive(deviceToken: deviceToken)
		}
	}

	func didFailToRegisterForRemoteNotificationsWithError(_ error: any Error) {
		WatchNotificationRegistrationService.shared.registrationFailed(error)
	}
}
