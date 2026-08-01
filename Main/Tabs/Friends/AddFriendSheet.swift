import SwiftUI

struct AddFriendSheet: View {
	@Environment(\.dismiss) private var dismiss
	@State private var query = ""
	@State private var results: [FriendSearchResult] = []
	@State private var service = FriendService.shared
	@State private var isSearching = false
	@State private var completedSearchQuery = ""
	@State private var isSearchPresented = false

	private var cleanedQuery: String {
		query.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	var body: some View {
		NavigationStack {
			ZStack {
				if cleanedQuery.isEmpty {
					ContentUnavailableView(
						"Find a Friend",
						systemImage: "person.2",
						description: Text("Search by name or school email address.")
					)
					.transition(.blurReplace)
				} else if results.isEmpty,
				          isSearching || completedSearchQuery != cleanedQuery
				{
					Color.clear
						.transition(.blurReplace)
				} else if results.isEmpty,
				          !isSearching,
				          completedSearchQuery == cleanedQuery
				{
					ContentUnavailableView.search(text: cleanedQuery)
						.transition(.blurReplace)
				} else {
					List {
						ForEach(results) { result in
							FriendSearchRow(result: result)
								.listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
								.listRowBackground(Image("paper").resizable().scaledToFill())
								.transition(.blurReplace)
						}
					}
					.listStyle(.insetGrouped)
					.animation(.snappy, value: results.map(\.id))
					.scrollEdgeEffectStyle(.soft, for: .top)
					.scrollEdgeEffectStyle(.soft, for: .bottom)
					.transition(.blurReplace)
				}
			}
			.animation(.easeOut(duration: 0.25), value: "\(cleanedQuery)\(results.isEmpty)\(isSearching)")
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
			.searchable(
				text: $query,
				isPresented: $isSearchPresented,
				prompt: "Search by name or email"
			)
			.onChange(of: query) { _, value in
				let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
				completedSearchQuery = ""
				Task { await search(for: cleaned) }
			}
			.onChange(of: isSearching) { _, searching in
				if !searching {
					completedSearchQuery = cleanedQuery
				}
			}
		}
	}

	private func search(for query: String) async {
		guard !query.isEmpty else {
			results = []
			isSearching = false
			return
		}

		isSearching = true
		defer { isSearching = false }
		do {
			results = try await service.search(query: query)
		} catch {
			results = []
		}
	}
}
