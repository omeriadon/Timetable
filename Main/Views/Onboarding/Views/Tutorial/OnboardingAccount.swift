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
						Image(systemName: "checkmark.circle.fill")
							.font(.system(size: 88, weight: .medium))
							.foregroundStyle(.green)
							.symbolRenderingMode(.hierarchical)

						Text("Account Ready")
							.font(.title.bold())

						Text("Your account is connected. Continue to import and sync your timetable.")
							.font(.title3)
							.multilineTextAlignment(.center)
							.foregroundStyle(.secondary)
					}
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
		.onChange(of: sessionStore.state) { _, _ in updateContext() }
	}

	private func updateContext() {
		context.configure(
			canAdvance: sessionStore.isAuthenticated,
			statusMessage: sessionStore.isAuthenticated ? "Account ready." : "Sign in or create an account to continue."
		)
	}
}
