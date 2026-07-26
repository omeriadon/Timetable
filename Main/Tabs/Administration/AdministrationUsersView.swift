import SwiftUI

struct AdministrationUsersView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var editor: AdministrationUserEditorTarget?
	@Namespace private var userEditorNamespace

	var body: some View {
		List(filteredUsers) { user in
			Button {
				editor = .edit(user)
			} label: {
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
					Image(systemName: "person")
				}
			}
			.matchedTransitionSource(id: user.id, in: userEditorNamespace)
		}
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Add User", systemImage: "plus", role: .confirm) {
					editor = .create
				}
				.buttonStyle(.glassProminent)
				.matchedTransitionSource(id: AdministrationUserEditorTarget.create.id, in: userEditorNamespace)
			}
		}
		.task {
			users = await (try? service.users()) ?? []
		}
		.sheet(item: $editor) { target in
			AdministrationUserEditor(
				target: target,
				didSave: save,
				didDelete: delete
			)
			.presentationDetents([.fraction(0.6)])
			.navigationTransition(.zoom(sourceID: target.id, in: userEditorNamespace))
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
}

enum AdministrationUserEditorTarget: Identifiable {
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
