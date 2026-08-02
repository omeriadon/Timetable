//
//   MobileAppDelegate.swift
//   Main
//
//   Created by Adon Omeri on 29/6/2026.
//

#if os(iOS)
	import UIKit
	import UserNotifications

	@MainActor
	final class MobileAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
		func application(
			_: UIApplication,
			didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
		) -> Bool {
			UNUserNotificationCenter.current().delegate = self
			return true
		}

		func applicationDidBecomeActive(_: UIApplication) {
			guard Platform.current == .iPadOS else { return }
			for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
				scene.sizeRestrictions?.minimumSize = CGSize(width: 900, height: 600)
			}
		}

		func application(
			_: UIApplication,
			didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
		) {
			Task {
				await NotificationRegistrationService.shared.receive(deviceToken: deviceToken)
			}
		}

		func application(
			_: UIApplication,
			didFailToRegisterForRemoteNotificationsWithError error: any Error
		) {
			NotificationRegistrationService.shared.registrationFailed(error)
			PrintError("APNs registration failed", category: .network, error: error)
		}

		func application(
			_: UIApplication,
			didReceiveRemoteNotification userInfo: [AnyHashable: Any]
		) async -> UIBackgroundFetchResult {
			await BroadcastNotificationCleanup.removeDeliveredNotification(for: userInfo)
			return .newData
		}

		func userNotificationCenter(
			_: UNUserNotificationCenter,
			willPresent notification: UNNotification
		) async -> UNNotificationPresentationOptions {
			Task {
				await refreshFriendStateIfNeeded(for: notification)
			}
			[.banner, .sound, .badge]
		}

		func userNotificationCenter(
			_: UNUserNotificationCenter,
			didReceive response: UNNotificationResponse
		) async {
			await refreshFriendStateIfNeeded(for: response.notification)
		}

		private func refreshFriendStateIfNeeded(for notification: UNNotification) async {
			guard notification.request.content.userInfo["notification-type"] as? String == "friend-request" else {
				return
			}

			do {
				try await FriendService.shared.refresh()
			} catch {
				PrintError("Unable to refresh friend state after notification", category: .network, error: error)
			}
		}
	}
#endif
