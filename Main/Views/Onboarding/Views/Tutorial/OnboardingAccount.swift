//
//  OnboardingAccount.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct OnboardingAccountView: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		ScrollView {
			VStack(spacing: 30) {
				Text("Set up an account to use the most of Timetable, including Live Activities, server syncing, notifications, sharing timetables, search, and more!")
					.font(.title2)
					.multilineTextAlignment(.leading)
				
				AccountAuthenticationView()
			}
		}
		.onAppear {
			context.configure(canAdvance: true, statusMessage: "Account creation is optional.")
		}
	}
}
