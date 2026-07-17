//
//  CalendarPermission.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Defaults
import EventKit
import SwiftUI
import UIKit
import UserNotifications

struct OnboardingCalendarPermissionView: View {
	@Environment(\.onboardingPageContext) private var context
	@Environment(\.scenePhase) private var scenePhase
	@State private var eventStore = EKEventStore()

	var body: some View {
		VStack(spacing: 40) {
			Image(systemName: "calendar.badge.checkmark")
				.font(.system(size: 72))
			Text("Timetable requires calendar access to import and maintain your school schedule.")
				.multilineTextAlignment(.center)
			if authorizationStatus == .denied || authorizationStatus == .restricted {
				Button("Open Settings", systemImage: "gear") {
					UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
				}
				.buttonStyle(.glassProminent)
			} else if !context.canAdvance {
				Button("Allow Calendar Access", systemImage: "calendar") {
					Task { await requestAccess() }
				}
				.controlSize(.extraLarge)
				.buttonStyle(.glassProminent)
			}
		}
		.onAppear { refreshStatus() }
		.onChange(of: scenePhase) { _, phase in
			if phase == .active {
				refreshStatus()
			}
		}
	}

	private var authorizationStatus: EKAuthorizationStatus {
		EKEventStore.authorizationStatus(for: .event)
	}

	private func refreshStatus() {
		let granted = authorizationStatus == .fullAccess
		context.configure(
			canAdvance: granted,
			statusMessage: granted ? "Calendar access granted." : "Calendar access is required to continue."
		)
	}

	private func requestAccess() async {
		context.isWorking = true
		defer { context.isWorking = false }
		do {
			_ = try await eventStore.requestFullAccessToEvents()
		} catch {
			context.statusMessage = error.localizedDescription
		}
		refreshStatus()
	}
}
