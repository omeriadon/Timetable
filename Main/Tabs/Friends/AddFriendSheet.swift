import SwiftUI

struct AddFriendSheet: View {
	let close: () -> Void
	let embedsInNavigation: Bool
	let showsCloseButton: Bool
	@State private var query = ""
	@State private var results: [FriendSearchResult] = []
	@State private var service = FriendService.shared
	@State private var isSearching = false
	@State private var completedSearchQuery = ""

	init(
		close: @escaping () -> Void,
		embedsInNavigation: Bool = true,
		showsCloseButton: Bool = true
	) {
		self.close = close
		self.embedsInNavigation = embedsInNavigation
		self.showsCloseButton = showsCloseButton
	}

	private var cleanedQuery: String {
		query.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	var body: some View {
		if embedsInNavigation {
			NavigationStack {
				content
			}
		} else {
			content
		}
	}

	private var content: some View {
		ZStack {
			if cleanedQuery.isEmpty {
				ContentUnavailableView(
					"Find a Friend",
					systemImage: "person.2",
					description: Text("Search by name to find friends.")
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
							.glurListRowBackground()
							.listRowSeparator(.hidden)
							.id(result.id)
							.transition(.blurReplace)
					}
				}
				.animation(.snappy, value: results.map(\.id))
				.scrollEdgeEffectStyle(.soft, for: .top)
				.scrollEdgeEffectStyle(.soft, for: .bottom)
				.transition(.blurReplace)
			}
		}
		.scrollContentBackground(.hidden)
		.searchable(text: $query, prompt: Text("Search by name"))
		.animation(.easeOut(duration: 0.25), value: "\(cleanedQuery)\(results.isEmpty)\(isSearching)")
		.appNavigationTitle("Add a Friend")
		.toolbar {
			DefaultToolbarItem(kind: .search, placement: .bottomBar)

			if showsCloseButton {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", role: .cancel) {
						close()
					}
					.labelStyle(.iconOnly)
				}
			}
		}
		.task(id: query) {
			completedSearchQuery = ""
			await search(for: cleanedQuery)
		}
	}

	private func search(for query: String) async {
		guard query.count >= 2 else {
			results = []
			isSearching = false
			return
		}

		isSearching = true
		defer {
			if !Task.isCancelled {
				isSearching = false
				completedSearchQuery = query
			}
		}
		do {
			let searchResults = try await service.search(query: query)
			guard !Task.isCancelled else { return }
			results = searchResults
		} catch {
			guard !Task.isCancelled else { return }
			results = []
		}
	}
}
