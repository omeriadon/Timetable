//
//   AppDelegate.swift
//   Main
//
//   Created by Adon Omeri on 16/6/2026.
//

import SwiftUI
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
	func applicationDidFinishLaunching(_: Notification) {
		guard let window = NSApplication.shared.windows.first else { return }
		StatusBadgeOverlayWindowController.shared.start()

		window.isOpaque = false
		window.backgroundColor = .clear

		window.titlebarAppearsTransparent = true
		UNUserNotificationCenter.current().delegate = self
		Task {
			await NotificationRegistrationService.shared.uploadPendingToken()
		}
	}

	func applicationWillFinishLaunching(_: Notification) {
		NSWindow.allowsAutomaticWindowTabbing = false

		if let mainMenu = NSApp.mainMenu {
			let editMenuIndex = mainMenu.indexOfItem(withTitle: "View")

			if editMenuIndex <= 0 {
				mainMenu.removeItem(at: editMenuIndex)
			}

			let fileMenuIndex = mainMenu.indexOfItem(withTitle: "File")

			if fileMenuIndex <= 0 {
				mainMenu.removeItem(at: editMenuIndex)
			}
		}
	}

	func application(_: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		Task { await NotificationRegistrationService.shared.receive(deviceToken: deviceToken) }
	}

	func application(_: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		NotificationRegistrationService.shared.registrationFailed(error)
	}

	func userNotificationCenter(
		_: UNUserNotificationCenter,
		willPresent _: UNNotification
	) async -> UNNotificationPresentationOptions {
		[.banner, .sound, .badge]
	}
}
