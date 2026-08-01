import SwiftUI

struct AdministrationSpecialBadgeUsersView: View {
	let users: [AdministrationUserResponse]
	@Binding var selectedUserIDs: Set<UUID>
	@State private var searchText = ""

	var body: some View {
		List(filteredUsers) { user in
			Button {
				toggle(user)
			} label: {
				HStack(spacing: 12) {
					ProfilePicture(
						appearance: user.appearance,
						photo: user.photo,
						size: 44,
						badges: user.badges,
						accessibilityName: user.displayName
					)

					VStack(alignment: .leading, spacing: 4) {
						Text(user.displayName)
						if let email = user.email {
							Text(email)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}

					Spacer()

					if selectedUserIDs.contains(user.id) {
						Image(systemName: "checkmark.circle.fill")
							.foregroundStyle(.accent)
					}
				}
			}
			.buttonStyle(.plain)
		}
		.searchable(text: $searchText, prompt: "Search users")
		.navigationTitle("Users")
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

	private func toggle(_ user: AdministrationUserResponse) {
		if selectedUserIDs.contains(user.id) {
			selectedUserIDs.remove(user.id)
		} else {
			selectedUserIDs.insert(user.id)
		}
	}
}
