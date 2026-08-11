import SwiftUI

struct AdministrationUsersView: View {
	let closeWideDestination: (() -> Void)?
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var editor: AdministrationUserEditorTarget?
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation

	var body: some View {
		List(filteredUsers) { user in
			if presentation == .iOS {
				Button {
					editor = .edit(user)
				} label: {
					userLabel(user)
						.glurListRowBackground()
				}
			} else {
				NavigationLink {
					AdministrationUserEditor(
						target: .edit(user),
						didSave: save,
						didDelete: delete,
						close: closeWideEditor
					)
				} label: {
					userLabel(user)
						.glurListRowBackground()
				}
			}
		}
		.appPaperBackground()
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				if presentation == .iOS {
					Button(role: .confirm) {
						editor = .create
					} label: {
						Label("Add User", systemImage: "plus")
							.foregroundStyle(.primary)
					}
					.buttonStyle(.glassProminent)
				} else {
					NavigationLink {
						AdministrationUserEditor(
							target: .create,
							didSave: save,
							didDelete: delete,
							close: closeWideEditor
						)
					} label: {
						Label("Add User", systemImage: "plus")
							.foregroundStyle(.primary)
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
			.appPaperPresentation()
		}
	}

	private func closeWideEditor() {
		closeWideDestination?()
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

				Text(user.email)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
	}

	private var filteredUsers: [AdministrationUserResponse] {
		guard !searchText.isEmpty else {
			return users
		}

		return users.filter {
			$0.displayName.localizedCaseInsensitiveContains(searchText)
				|| $0.email.localizedCaseInsensitiveContains(searchText)
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
