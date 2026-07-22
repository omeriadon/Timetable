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
			Group {
				if sessionStore.isAuthenticated {
					VStack(spacing: 20) {
						Image(systemName: "checkmark")
							.font(.system(size: 88, weight: .medium))
							.foregroundStyle(.white)
							.symbolRenderingMode(.hierarchical)

						Text("Account Ready")
							.font(.title.bold())

						Text("Your account is connected.")
							.font(.title3)
							.multilineTextAlignment(.center)
					}
					.padding(.top, 100)
					.frame(maxWidth: .infinity, minHeight: 360)
				} else {
					VStack(spacing: 30) {
						Text("Create or sign in to an account before importing your timetable. This enables server syncing, sharing, search, and notifications.")
							.font(.title2)
							.multilineTextAlignment(.leading)

						AccountAuthenticationView()
					}
				}
			}
			.padding(.vertical, 8)
			.transition(.blurReplace)
			.animation(.snappy, value: sessionStore.isAuthenticated)
		}
		.onAppear { updateContext() }
		.onChange(of: sessionStore.state) { updateContext() }
	}

	private func updateContext() {
		context.configure(
			canAdvance: sessionStore.isAuthenticated,
			statusMessage: sessionStore.isAuthenticated ? "Account ready." : "Sign in or create an account to continue."
		)
	}
}
