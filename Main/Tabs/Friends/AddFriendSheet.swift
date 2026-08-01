import SwiftUI

struct AddFriendSheet: View {
	@Environment(\.dismiss) private var dismiss
	@State private var schoolEmail = ""
	@State private var results: [FriendSearchResult] = []
	@State private var service = FriendService.shared
	@State private var isSearching = false

	var body: some View {
		NavigationStack {
			List {
				Section {
					TextField("School email", text: $schoolEmail)
						.textInputAutocapitalization(.never)
						.keyboardType(.emailAddress)
						.autocorrectionDisabled()
						.textContentType(.emailAddress)
				} footer: {
					Text("Friends are found using their school email address.")
				}

				if isSearching {
					ProgressView()
						.frame(maxWidth: .infinity)
						.listRowBackground(Color.clear)
				} else {
					ForEach(results) { result in
						FriendSearchRow(result: result)
							.listRowBackground(Image("paper").resizable().scaledToFill())
					}
				}
			}
			.listStyle(.insetGrouped)
			.appNavigationTitle("Add a Friend")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					} label: {
						Image(systemName: "xmark")
					}
				}
			}
			.onChange(of: schoolEmail) { _, value in
				Task { await search(for: value) }
			}
		}
	}

	private func search(for value: String) async {
		let query = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard query.contains("@") else {
			results = []
			return
		}
		isSearching = true
		defer { isSearching = false }
		do {
			results = try await service.search(schoolEmail: query)
		} catch {
			results = []
		}
	}
}
