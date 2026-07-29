import SwiftUI

struct AdministrationAdministratorsView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var pendingChange: AdministratorAuthorityChange?
	@State private var isUpdating = false

	var body: some View {
		List {
			Section {
				ForEach(users) { user in
					administratorRow(for: user)
				}
			} footer: {
				Text("Only permanent owners can change administrator access. Permanent owners cannot be changed here.")
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Administrators", accent: true)
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
			Label {
				VStack(alignment: .leading) {
					Text(user.displayName)
					Text("Permanent Owner")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			} icon: {
				Image(systemName: "crown.fill")
					.foregroundStyle(.yellow)
			}
		} else {
			Toggle(isOn: administratorBinding(for: user)) {
				Label {
					VStack(alignment: .leading) {
						Text(user.displayName)

						if let email = user.email {
							Text(email)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
				} icon: {
					Image(systemName: "person.badge.shield.checkmark")
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
