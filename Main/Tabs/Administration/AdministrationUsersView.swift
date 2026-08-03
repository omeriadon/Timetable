import SwiftUI

struct AdministrationUsersView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var editor: AdministrationUserEditorTarget?
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation
	@Environment(\.closeWideNavigationDestination) private var closeWideNavigationDestination

	var body: some View {
		List(filteredUsers) { user in
			if presentation == .iOS {
				Button {
					editor = .edit(user)
				} label: {
					userLabel(user)
				}
			} else {
				NavigationLink {
					AdministrationUserEditor(
						target: .edit(user),
						didSave: save,
						didDelete: delete,
						close: closeWideNavigationDestination
					)
				} label: {
					userLabel(user)
				}
			}
		}
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				if presentation == .iOS {
					Button(role: .confirm) {
						editor = .create
					} label: {
						Label("Add User", systemImage: "plus")
							.foregroundStyle(.white)
					}
					.buttonStyle(.glassProminent)
				} else {
					NavigationLink {
						AdministrationUserEditor(
							target: .create,
							didSave: save,
							didDelete: delete,
							close: closeWideNavigationDestination
						)
					} label: {
						Label("Add User", systemImage: "plus")
							.foregroundStyle(.white)
					}
					.buttonStyle(.glassProminent)
				}
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
				didDelete: delete,
				close: { editor = nil }
			)
			.presentationDetents(editor == .create ? [.fraction(0.6)] : [.large])
		}
	}

	private func userLabel(_ user: AdministrationUserResponse) -> some View {
		HStack(spacing: 12) {
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
				Text(user.authority.displayName)
					.font(.caption)
					.foregroundStyle(authorityColor(for: user.authority))

				if let email = user.email {
					Text(email)
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			}
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
