import UserNotifications

enum BroadcastNotificationCleanup {
	static func removeDeliveredNotification(for userInfo: [AnyHashable: Any]) async {
		guard let broadcastID = userInfo["broadcast-id"] as? String else {
			return
		}

		let center = UNUserNotificationCenter.current()
		let delivered = await center.deliveredNotifications()
		let identifiers: [String] = delivered.compactMap { notification in
			guard notification.request.content.userInfo["broadcast-id"] as? String == broadcastID else {
				return nil
			}

			return notification.request.identifier
		}
		center.removeDeliveredNotifications(withIdentifiers: identifiers)
	}
}
