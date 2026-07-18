import SwiftUI

struct NonAuthoritativeAccountView: View {
	@State private var sessionStore = SessionStore.shared

	var body: some View {
		Form {
			if case let .authenticated(profile) = sessionStore.state {
				Section("Profile") {
					LabeledContent("Name", value: profile.displayName)
					if let email = profile.email {
						LabeledContent("Email", value: email)
					}
				}
			}
			Section {
				Button("Sign Out", role: .destructive) { Task { await sessionStore.signOut() } }
			}
		}
		.appNavigationTitle("Account")
	}
}
