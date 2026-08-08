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
	@Environment(\.statusBadgeManager) private var badges
	@State private var service = LocationStatusService.shared

	var body: some View {
		ZStack {
			AccountBackgroundView(profile: Defaults[.accountProfile])
				.ignoresSafeArea()

			switch sessionStore.state {
				case let .authenticated(profile):
					Group {
						List { accountRows(profile: profile) }
							.listStyle(.insetGrouped)
							.scrollContentBackground(.hidden)
					}
					.task(id: profile.id) {
						await loadYearGroups()
					}
					.appNavigationTitle("Account")
					.transition(.blurReplace)
				case .restoring:
					if let cachedProfile = Defaults[.accountProfile] {
						List { accountRows(profile: cachedProfile) }
							.listStyle(.insetGrouped)
							.scrollContentBackground(.hidden)
							.appNavigationTitle("Account")
					} else {
						ProgressView("Restoring Account…")
					}
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
			ProfileAppearanceSheet(close: { showsProfileEditor = false })
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
			LabeledContent("Name") {
				TextField("Name", text: $displayName)
					.multilineTextAlignment(.trailing)
					.submitLabel(.done)
			}
			.onChange(of: displayName) { _, value in
				ServerSyncCoordinator.shared.scheduleProfileUpdate(value)
			}
			if let email = profile.email {
				LabeledContent("Email", value: email)
			}
		}
		.listRowBackground(Rectangle().fill(.thinMaterial))

		Section {
			if isLoadingYearGroups, yearGroupTags.isEmpty {
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
		.listRowBackground(Rectangle().fill(.thinMaterial))

		if service.authorizationStatus != .authorizedAlways {
			Section("Status") {
				Button("Open Location Settings", systemImage: "location.fill") {
					if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(settingsURL)
					}
				}
			}
			.listRowBackground(Rectangle().fill(.thinMaterial))
		}

		Section {
			Button("Sign Out", systemImage: "door.right.hand.open", role: .destructive, action: signOut)

			Button("Delete Account", systemImage: "trash", role: .destructive) { showDeleteConfirmation = true }
				.disabled(isDeleting)
				.foregroundStyle(.red)
		}
		.listRowBackground(Rectangle().fill(.thinMaterial))
	}

	private func signOut() {
		Task {
			await sessionStore.signOut()
		}
	}

	@MainActor
	private func loadYearGroups() async {
		let cachedCatalogue = Defaults[.eventTagCatalogue]
		let cachedSubscriptions = Set(Defaults[.eventTagSubscriptionIDs])
		let cachedTags = cachedCatalogue.sections.first(where: { $0.category == .yearGroup })?.tags ?? []
		if !cachedTags.isEmpty {
			applyYearGroupData(tags: cachedTags, subscribedTagIDs: cachedSubscriptions)
		}
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
				?? tags.first(where: { $0.displayName == "Year 7" })?.id
				?? tags.first?.id

			yearGroupTags = tags
			self.subscribedTagIDs = subscribedTagIDs
			self.selectedYearGroupID = selectedYearGroupID
			committedYearGroupID = selectedYearGroupID

			if !tags.contains(where: { subscribedTagIDs.contains($0.id) }),
			   let selectedYearGroupID
			{
				await saveYearGroup(selectedYearGroupID)
			}
		} catch {
			if yearGroupTags.isEmpty {
				yearGroupTags = []
				subscribedTagIDs = []
				selectedYearGroupID = nil
				committedYearGroupID = nil
			}
			yearGroupsFailedToLoad = true
			badges.present(error: error, title: "Unable to load year groups")
		}
	}

	@MainActor
	private func applyYearGroupData(tags: [EventTagCatalogueTag], subscribedTagIDs: Set<UUID>) {
		let selectedYearGroupID = tags.first(where: { subscribedTagIDs.contains($0.id) })?.id
			?? tags.first(where: { $0.displayName == "Year 7" })?.id
			?? tags.first?.id
		yearGroupTags = tags
		self.subscribedTagIDs = subscribedTagIDs
		self.selectedYearGroupID = selectedYearGroupID
		committedYearGroupID = selectedYearGroupID
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
