//
//   MobileAppDelegate.swift
//   Main
//
//   Created by Codex on 29/6/2026.
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

		func application(
			_: UIApplication,
			didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
		) {
			Task {
				await NotificationRegistrationService.shared.upload(deviceToken: deviceToken)
			}
		}

		func application(
			_: UIApplication,
			didFailToRegisterForRemoteNotificationsWithError error: any Error
		) {
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
