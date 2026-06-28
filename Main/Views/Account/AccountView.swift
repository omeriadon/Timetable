//
//   AccountView.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import SwiftUI

struct AccountView: View {
	@State private var sessionStore = SessionStore.shared

	var body: some View {
		Group {
			switch sessionStore.state {
				case let .authenticated(profile):
					List {
						Section("Profile") {
							LabeledContent("Name", value: profile.displayName)
							if let email = profile.email {
								LabeledContent("Email", value: email)
							}
						}

						Section {
							Button("Sign Out", role: .destructive, action: signOut)
							Button("Delete Account", role: .destructive, action: deleteAccount)
						}
					}
					.navigationTitle("Account")
				case .restoring:
					ProgressView("Restoring Account…")
				case .signedOut:
					AccountAuthenticationView()
			}
		}
		.transition(.blurReplace)
		.animation(.snappy, value: sessionStore.state)
	}

	private func signOut() {
		Task {
			await sessionStore.signOut()
		}
	}

	private func deleteAccount() {
		Task {
			try await sessionStore.deleteAccount()
		}
	}
}
