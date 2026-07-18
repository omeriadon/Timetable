//
//  OnboardingAccount.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct OnboardingAccountView: View {
	@Environment(\.onboardingPageContext) private var context
	@State private var sessionStore = SessionStore.shared

	var body: some View {
		ScrollView {
			VStack(spacing: 30) {
				Text("Create or sign in to an account before importing your timetable. This enables server syncing, sharing, search, and notifications.")
					.font(.title2)
					.multilineTextAlignment(.leading)

				AccountAuthenticationView()
			}
			.padding(.vertical, 8)
		}
		.onAppear { updateContext() }
		.onChange(of: sessionStore.state) { _, _ in updateContext() }
	}

	private func updateContext() {
		context.configure(
			canAdvance: sessionStore.isAuthenticated,
			statusMessage: sessionStore.isAuthenticated ? "Account ready." : "Sign in or create an account to continue."
		)
	}
}
