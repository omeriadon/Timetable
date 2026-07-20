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

		func userNotificationCenter(
			_: UNUserNotificationCenter,
			willPresent _: UNNotification
		) async -> UNNotificationPresentationOptions {
			[.banner, .sound, .badge]
		}
	}
#endif
