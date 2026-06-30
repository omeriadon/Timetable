//
//   AccountView.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import SwiftUI

struct AccountView: View {
	@State private var sessionStore = SessionStore.shared
	@Default(.userDisplayName) private var displayName

	var body: some View {
		Group {
			switch sessionStore.state {
				case let .authenticated(profile):
					List {
						Section("Profile") {
							#if os(iOS)
								TextField("Name", text: $displayName)
									.submitLabel(.done)
									.onChange(of: displayName) { _, value in ServerSyncCoordinator.shared.scheduleProfileUpdate(value) }
							#else
								LabeledContent("Name", value: profile.displayName)
							#endif
							if let email = profile.email {
								LabeledContent("Email", value: email)
							}
						}

						Section {
							Button("Sign Out", role: .destructive, action: signOut)
							Button("Delete Account", role: .destructive, action: deleteAccount)
						}
					}
					.appNavigationTitle("Account")
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
