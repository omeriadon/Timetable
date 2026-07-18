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
	@State private var showDeleteConfirmation = false
	@State private var isDeleting = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		ZStack {
			switch sessionStore.state {
				case let .authenticated(profile):
					Group {
						#if os(macOS)
							Form { accountRows(profile: profile) }
								.formStyle(.grouped)
								.scrollContentBackground(.hidden)
						#else
							List { accountRows(profile: profile) }
								.listStyle(.insetGrouped)
						#endif
					}
					.appNavigationTitle("Account")
					.transition(.blurReplace)
				case .restoring:
					ProgressView("Restoring Account…")
						.transition(.blurReplace)
				case .signedOut:
					ScrollView {
						AccountAuthenticationView()
					}
					.scrollBounceBehavior(.basedOnSize)
					.scrollEdgeEffectStyle(.none, for: .vertical)
					.transition(.blurReplace)
			}
		}
		.alert("Delete Account?", isPresented: $showDeleteConfirmation) {
			Button("Cancel", role: .cancel) {}
			Button("Delete Account", role: .destructive) { deleteAccount() }
		} message: {
			Text("This permanently deletes your account and server data.")
		}
		.animation(.easeInOut, value: sessionStore.state)
	}

	@ContentBuilder
	private func accountRows(profile: AccountProfile) -> some View {
		Section("Profile") {
			#if os(iOS)
				LabeledContent("Name") {
					TextField("Name", text: $displayName)
						.multilineTextAlignment(.trailing)
						.submitLabel(.done)
				}
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
				.foregroundStyle(.red)
			#if os(iOS)
				Button("Delete Account", role: .destructive) { showDeleteConfirmation = true }
					.disabled(isDeleting)
			#endif
		}
	}

	private func signOut() {
		Task {
			await sessionStore.signOut()
		}
	}

	private func deleteAccount() {
		Task {
			isDeleting = true
			defer { isDeleting = false }
			do {
				try await sessionStore.deleteAccount()
			} catch {
				badges.addBadge(id: UUID(), title: "Unable to delete account", secondaryText: error.localizedDescription, priority: 4, view: .error)
			}
		}
	}
}
