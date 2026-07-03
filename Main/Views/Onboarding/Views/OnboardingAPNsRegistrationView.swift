//
//  OnboardingAPNsRegistrationView.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Defaults
import EventKit
import SwiftUI
import UIKit
import UserNotifications

struct OnboardingAPNsRegistrationView: View {
	@Environment(\.onboardingPageContext) private var context
	@State private var registration = NotificationRegistrationService.shared

	var body: some View {
		VStack(spacing: 24) {
			Image(systemName: registration.hasLocalToken ? "checkmark.seal.fill" : "antenna.radiowaves.left.and.right")
				.font(.system(size: 72))
			Text(registration.hasLocalToken ? "This device is ready for push services." : "Registering this installation with Apple Push Notification service.")
				.multilineTextAlignment(.center)
			if case let .failed(message) = registration.registrationState {
				Text(message).foregroundStyle(.red).multilineTextAlignment(.center)
				Button("Try Again", systemImage: "arrow.clockwise") {
					registration.requestRemoteRegistration()
				}
				.buttonStyle(.glassProminent)
			} else if !registration.hasLocalToken {
				ProgressView()
			}
		}
		.onAppear {
			context.configure(canAdvance: registration.hasLocalToken, isWorking: !registration.hasLocalToken)
			if !registration.hasLocalToken { registration.requestRemoteRegistration() }
		}
		.onChange(of: registration.hasLocalToken) { _, hasToken in
			context.configure(canAdvance: hasToken, isWorking: !hasToken)
		}
	}
}
