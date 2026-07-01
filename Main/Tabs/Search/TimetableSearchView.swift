import PassKit
import SwiftUI

struct TimetableSearchView: View {
	@State private var query = ""
	@State private var service = TimetableDiscoveryService.shared
	@State private var sessionStore = SessionStore.shared

	var body: some View {
		NavigationStack {
			Group {
				if !sessionStore.isAuthenticated {
					ContentUnavailableView("Sign In Required", systemImage: "person.crop.circle.badge.exclamationmark", description: Text("Sign in to search timetables."))
				} else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					SearchLandingView()
				} else if !(3 ..< 50).contains(query.trimmingCharacters(in: .whitespacesAndNewlines).count) {
					ContentUnavailableView("Keep Typing", systemImage: "text.magnifyingglass", description: Text("Search terms must contain 3 to 49 characters."))
				} else if service.results.isEmpty, !service.isSearching {
					ContentUnavailableView.search(text: query)
				} else {
					List(service.results) { result in
						NavigationLink(value: result) { TimetableSearchRow(result: result) }
							.listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
					}
					.animation(.snappy, value: service.results.map(\.id))
					.refreshable { service.search(query, immediately: true) }
				}
			}
			.overlay { if service.isSearching { ProgressView().controlSize(.large) } }
			.appNavigationTitle("Search")
			.searchable(text: $query, prompt: "Timetable or author")
			.onChange(of: query) { if sessionStore.isAuthenticated { service.search(query) } }
			.navigationDestination(for: TimetableSearchResult.self) { TimetableDetailView(result: $0) }
		}
	}
}

private struct SearchLandingView: View {
	var body: some View {
		ContentUnavailableView("Search Timetables", systemImage: "magnifyingglass", description: Text("Enter at least three characters."))
	}
}

private struct TimetableSearchRow: View {
	let result: TimetableSearchResult
	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: result.sourceKind == .accountOwner ? "person.crop.rectangle" : "person.2.crop.square.stack")
				.font(.title2).foregroundStyle(.tint).frame(width: 34)
			VStack(alignment: .leading, spacing: 6) {
				Text(result.title).font(.headline).lineLimit(2)
				Text(result.authorDisplayName).foregroundStyle(.secondary).lineLimit(1)
			}
		}
		.frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
	}
}
