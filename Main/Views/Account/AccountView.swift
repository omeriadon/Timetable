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
	@State private var showsProfileEditor = false
	@State private var isDeleting = false
	@Namespace private var profileNamespace
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
		.sheet(isPresented: $showsProfileEditor) {
			ProfileAppearanceSheet()
				.navigationTransition(.zoom(sourceID: "account-profile-editor", in: profileNamespace))
				.presentationDetents([.fraction(0.7)])
				.presentationDragIndicator(.hidden)
		}
		.animation(.easeInOut, value: sessionStore.state)
	}

	@ContentBuilder
	private func accountRows(profile: AccountProfile) -> some View {
		Section("Profile") {
			Button {
				showsProfileEditor = true
			} label: {
				HStack(spacing: 12) {
					ProfilePicture(
						appearance: profile.appearance,
						photo: profile.photo,
						size: 44,
						badges: profile.badges,
						accessibilityName: profile.displayName
					)
					Label("Edit Profile", systemImage: "pencil")
				}
			}
			.matchedTransitionSource(id: "account-profile-editor", in: profileNamespace)
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
			Button("Sign Out", systemImage: "door.right.hand.open", role: .destructive, action: signOut)
			#if os(iOS)
				Button("Delete Account", systemImage: "trash", role: .destructive) { showDeleteConfirmation = true }
					.disabled(isDeleting)
					.foregroundStyle(.red)
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
