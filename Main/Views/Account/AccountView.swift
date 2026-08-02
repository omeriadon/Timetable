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
	@State private var yearGroupTags: [EventTagCatalogueTag] = []
	@State private var subscribedTagIDs: Set<UUID> = []
	@State private var selectedYearGroupID: UUID?
	@State private var committedYearGroupID: UUID?
	@State private var isLoadingYearGroups = false
	@State private var isSavingYearGroup = false
	@State private var yearGroupsFailedToLoad = false
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
					.task(id: profile.id) {
						await loadYearGroups()
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
				.presentationDetents([.large])
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
					Text("Edit Profile")
				}
				.foregroundStyle(.accent)
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

		Section("Year Group") {
			if isLoadingYearGroups {
				LabeledContent("Year Group") {
					ProgressView()
				}
			} else if yearGroupTags.isEmpty {
				if yearGroupsFailedToLoad {
					Button("Reload Year Groups", systemImage: "arrow.clockwise") {
						Task {
							await loadYearGroups()
						}
					}
				} else {
					Label("No Year Groups Available", systemImage: "person.3")
						.foregroundStyle(.secondary)
				}
			} else {
				Picker("Year Group", selection: $selectedYearGroupID) {
					Text("Select Year Group")
						.tag(UUID?.none)
					ForEach(yearGroupTags) { tag in
						Label(tag.displayName, systemImage: tag.symbol ?? "person.3")
							.tag(Optional(tag.id))
					}
				}
				.pickerStyle(.menu)
				.disabled(isSavingYearGroup)
				.onChange(of: selectedYearGroupID) { _, selectedYearGroupID in
					guard let selectedYearGroupID,
					      selectedYearGroupID != committedYearGroupID
					else {
						return
					}

					Task {
						await saveYearGroup(selectedYearGroupID)
					}
				}
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

	@MainActor
	private func loadYearGroups() async {
		isLoadingYearGroups = true
		yearGroupsFailedToLoad = false
		defer {
			isLoadingYearGroups = false
		}

		do {
			let catalogue = try await AdministrationService.shared.tagCatalogue()
			let subscriptions = try await AdministrationService.shared.tagSubscriptions()
			let tags = catalogue.sections.first(where: { $0.category == .yearGroup })?.tags ?? []
			let subscribedTagIDs = Set(subscriptions.tagIDs)
			let selectedYearGroupID = tags.first(where: { subscribedTagIDs.contains($0.id) })?.id

			yearGroupTags = tags
			self.subscribedTagIDs = subscribedTagIDs
			self.selectedYearGroupID = selectedYearGroupID
			committedYearGroupID = selectedYearGroupID
		} catch {
			yearGroupTags = []
			subscribedTagIDs = []
			selectedYearGroupID = nil
			committedYearGroupID = nil
			yearGroupsFailedToLoad = true
			badges.present(error: error, title: "Unable to load year groups")
		}
	}

	@MainActor
	private func saveYearGroup(_ selectedYearGroupID: UUID) async {
		isSavingYearGroup = true
		defer {
			isSavingYearGroup = false
		}

		let yearGroupIDs = Set(yearGroupTags.map(\.id))
		let proposedTagIDs = subscribedTagIDs
			.subtracting(yearGroupIDs)
			.union([selectedYearGroupID])

		do {
			let response = try await AdministrationService.shared.replaceTagSubscriptions(proposedTagIDs)
			subscribedTagIDs = Set(response.tagIDs)
			committedYearGroupID = yearGroupTags.first(where: { subscribedTagIDs.contains($0.id) })?.id
			self.selectedYearGroupID = committedYearGroupID
		} catch {
			self.selectedYearGroupID = committedYearGroupID
			badges.present(error: error, title: "Unable to save year group")
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
