import SwiftUI

struct AdministrationAdministratorsView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var pendingChange: AdministratorAuthorityChange?
	@State private var isUpdating = false

	var body: some View {
		List {
			Section {
				ForEach(filteredUsers) { user in
					administratorRow(for: user)
				}
			} footer: {
				Text("Only system administrators can change administrator access. System administrators cannot be changed here.")
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Administrators", accent: true)
		.searchable(text: $searchText, prompt: "Search users")
		.refreshable {
			await load()
		}
		.task {
			await load()
		}
		.confirmationDialog(
			pendingChange?.title ?? "Change Administrator Access?",
			isPresented: Binding(
				get: { pendingChange != nil },
				set: { isPresented in
					if !isPresented {
						pendingChange = nil
					}
				}
			),
			titleVisibility: .visible
		) {
			if let pendingChange {
				Button(pendingChange.actionTitle, systemImage: pendingChange.symbol, role: .confirm) {
					updateAuthority(pendingChange)
				}
			}
		} message: {
			Text(pendingChange?.message ?? "")
		}
	}

	@ViewBuilder
	private func administratorRow(for user: AdministrationUserResponse) -> some View {
		if user.authority == .systemOwner {
			HStack {
				ProfilePicture(
					appearance: user.appearance,
					photo: user.photo,
					size: 44,
					badges: user.badges,
					accessibilityName: user.displayName,
					animatesBackground: true
				)

				VStack(alignment: .leading) {
					Text(user.displayName)
					Text("System Administrator")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			}
		} else {
			Toggle(isOn: administratorBinding(for: user)) {
				HStack {
					ProfilePicture(
						appearance: user.appearance,
						photo: user.photo,
						size: 44,
						badges: user.badges,
						accessibilityName: user.displayName,
						animatesBackground: true
					)

					VStack(alignment: .leading) {
						Text(user.displayName)

						if let email = user.email {
							Text(email)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
				}
			}
			.disabled(isUpdating)
		}
	}

	private func administratorBinding(for user: AdministrationUserResponse) -> Binding<Bool> {
		Binding(
			get: { user.authority == .administrator },
			set: { shouldBeAdministrator in
				pendingChange = AdministratorAuthorityChange(
					user: user,
					authority: shouldBeAdministrator ? .administrator : .user
				)
			}
		)
	}

	private func load() async {
		users = await (try? service.users()) ?? []
	}

	private var filteredUsers: [AdministrationUserResponse] {
		guard !searchText.isEmpty else {
			return users
		}

		return users.filter {
			$0.displayName.localizedCaseInsensitiveContains(searchText)
				|| ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
		}
	}

	private func updateAuthority(_ change: AdministratorAuthorityChange) {
		isUpdating = true
		Task {
			defer {
				isUpdating = false
				pendingChange = nil
			}

			guard let updatedUser = try? await service.updateUserAuthority(
				id: change.user.id,
				authority: change.authority
			) else {
				return
			}

			guard let index = users.firstIndex(where: { $0.id == updatedUser.id }) else {
				return
			}

			users[index] = updatedUser
			await load()
			NotificationCenter.default.post(
				name: .administrationDashboardRefreshRequested,
				object: nil
			)
		}
	}
}

private struct AdministratorAuthorityChange {
	let user: AdministrationUserResponse
	let authority: AccountAuthority

	var title: String {
		authority == .administrator ? "Make Administrator?" : "Remove Administrator?"
	}

	var actionTitle: String {
		authority == .administrator ? "Make Administrator" : "Remove Administrator"
	}

	var symbol: String {
		authority == .administrator ? "shield.fill" : "shield.slash"
	}

	var message: String {
		"Change administrator access for \(user.displayName)."
	}
}
