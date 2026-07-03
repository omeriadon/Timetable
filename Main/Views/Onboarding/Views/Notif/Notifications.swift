//
//  Notifications.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Defaults
import EventKit
import SwiftUI
import UIKit
import UserNotifications

struct OnboardingNotificationPermissionView: View {
	@Environment(\.onboardingPageContext) private var context
	@State private var hasDecided = false

	var body: some View {
		VStack(spacing: 40) {
			Image(systemName: "bell.badge.fill")
				.font(.system(size: 72))

			Text("Enable notifications for class reminders and important school events. You can configure each category separately later.")
				.multilineTextAlignment(.center)

			Button("Enable Notifications", systemImage: "bell.fill") {
				Task { await requestAccess() }
			}
			.controlSize(.large)
			.font(.title2)
			.buttonStyle(.glassProminent)

			Button("Not Now") {
				disableNotificationPreferences()
				hasDecided = true
				context.configure(canAdvance: true, statusMessage: "Notifications remain disabled.")
			}
			.buttonStyle(.glass)
		}
		.onAppear {
			context.configure(canAdvance: hasDecided)
		}
	}

	private func requestAccess() async {
		context.isWorking = true
		defer { context.isWorking = false }
		do {
			let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
			hasDecided = true
			if !granted { disableNotificationPreferences() }
			context.configure(
				canAdvance: true,
				statusMessage: granted ? "Notifications enabled." : "Notifications remain disabled."
			)
		} catch {
			hasDecided = true
			disableNotificationPreferences()
			context.configure(canAdvance: true, statusMessage: error.localizedDescription)
		}
	}

	private func disableNotificationPreferences() {
		var settings = Defaults[.accountSettings]
		settings.notificationsEnabled = false
		settings.broadcastNotificationsEnabled = false
		Defaults[.accountSettings] = settings
	}
}
