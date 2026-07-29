import SwiftUI

struct AdministrationUsersView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var editor: AdministrationUserEditorTarget?
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List(filteredUsers) { user in
			Button {
				editor = .edit(user)
			} label: {
				Label {
					VStack(alignment: .leading) {
						Text(user.displayName)
						Text(user.authority.displayName)
							.font(.caption)
							.foregroundStyle(authorityColor(for: user.authority))

						if let email = user.email {
							Text(email)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
				} icon: {
					Image(systemName: "person")
				}
			}
		}
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button(role: .confirm) {
					editor = .create
				} label: {
					Label("Add User", systemImage: "plus")
						.foregroundStyle(.white)
				}
				.buttonStyle(.glassProminent)
			}
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.sheet(item: $editor) { target in
			AdministrationUserEditor(
				target: target,
				didSave: save,
				didDelete: delete
			)
			.presentationDetents(editor == .create ? [.fraction(0.6)] : [.large])
		}
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

	private func load() async {
		do {
			users = try await service.users()
		} catch {
			badges.present(error: error, title: "Unable to refresh users")
		}
	}

	private func update(_ user: AdministrationUserResponse) {
		guard let index = users.firstIndex(where: { $0.id == user.id }) else {
			return
		}

		users[index] = user
	}

	private func save(_ user: AdministrationUserResponse) {
		if users.contains(where: { $0.id == user.id }) {
			update(user)
		} else {
			users.append(user)
			users.sort { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
		}
	}

	private func delete(_ user: AdministrationUserResponse) {
		users.removeAll { $0.id == user.id }
	}

	private func authorityColor(for authority: AccountAuthority) -> Color {
		switch authority {
			case .systemOwner:
				.yellow
			case .administrator:
				.accentColor
			case .user:
				.secondary
		}
	}
}

enum AdministrationUserEditorTarget: Identifiable, Equatable {
	case create
	case edit(AdministrationUserResponse)

	var id: String {
		switch self {
			case .create:
				"create"
			case let .edit(user):
				user.id.uuidString
		}
	}

	var user: AdministrationUserResponse? {
		if case let .edit(user) = self {
			return user
		}

		return nil
	}
}
