import SwiftUI

struct AdministrationUsersView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var editor: AdministrationUserResponse?

	var body: some View {
		List(filteredUsers) { user in
			Button {
				editor = user
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
		}
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users")
		.task {
			users = await (try? service.users()) ?? []
		}
		.sheet(item: $editor) { user in
			AdministrationUserEditor(user: user) { updatedUser in
				update(updatedUser)
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

	private func update(_ user: AdministrationUserResponse) {
		guard let index = users.firstIndex(where: { $0.id == user.id }) else {
			return
		}

		users[index] = user
	}
}
