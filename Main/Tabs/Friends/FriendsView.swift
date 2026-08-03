import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct FriendsView: View {
	@Default(.friends) private var friends
	@Default(.incomingFriendRequests) private var incomingFriendRequests
	@State private var service = FriendService.shared
	@State private var searchText = ""
	@State private var searchResults: [FriendSearchResult] = []
	@State private var sheet: FriendsSheet?
	@State private var selectedFriend: FriendSummary?
	@State private var isSearching = false
	@State private var draggedFriend: FriendSummary?
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@Environment(\.appPresentation) private var presentation
	@Environment(AppRouter.self) private var router

	var body: some View {
		ZStack {
			if searchText.isEmpty {
				friendsList
					.transition(.blurReplace)
			} else {
				friendSearchResults
					.transition(.blurReplace)
			}
		}
		.animation(.easeInOut, value: searchText.isEmpty)
		.scrollEdgeEffect()
		.appNavigationTitle("Friends", style: .main, accent: true)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button("Friend requests", systemImage: incomingFriendRequests.isEmpty ? "bell" : "bell.badge") {
					if presentation == .iOS {
						sheet = .requests
					} else {
						router.navigate(to: .friends(.requests))
					}
				}
				.badge(incomingFriendRequests.count)
				.accessibilityValue(incomingFriendRequests.isEmpty ? "No pending requests" : "\(incomingFriendRequests.count) pending requests")
			}
			ToolbarItem(placement: .topBarTrailing) {
				Button("Add friend", systemImage: "person.badge.plus") {
					sheet = .addFriend
				}
			}
		}
		.searchable(text: $searchText, prompt: "Search with a school email")
		.task { await refresh() }
		.task(id: searchText) {
			await search(for: searchText)
		}
		.popover(item: $sheet) { sheet in
			Group {
				switch sheet {
					case .addFriend:
						AddFriendSheet(close: { self.sheet = nil })
							.presentationDetents([.large])
							.presentationDragIndicator(.hidden)
							.frame(iOS: .init(), macOS: .init(width: 620, height: 700))
					case .requests:
						FriendRequestsSheet(close: { self.sheet = nil })
							.presentationDetents([.fraction(0.6), .large])
							.presentationDragIndicator(.hidden)
							.frame(iOS: .init(), macOS: .init(width: 620, height: 700))
				}
			}
			.presentationCompactAdaptation(.sheet)
		}
		.sheet(item: $selectedFriend) { friend in
			FriendDetailView(friend: friend, close: { selectedFriend = nil })
		}
		.dynamicTypeSize(.medium)
	}

	private func animatedScrollCard(_ content: some View) -> some View {
		let shouldReduceMotion = reduceMotion

		return content
			.scrollTransition(.animated(.snappy(duration: 0.3))) { card, phase in
				card
					.opacity(shouldReduceMotion || phase.isIdentity ? 1 : 0.65)
					.scaleEffect(shouldReduceMotion || phase.isIdentity ? 1 : 0.96)
			}
	}

	private var friendsList: some View {
		ScrollView {
			LazyVStack(spacing: 14) {
				if friends.isEmpty {
					ContentUnavailableView(
						"No Friends Yet",
						systemImage: "person.2.slash",
						description: Text("Add friends using their school email address.")
					)
					.padding(.top, 72)
				} else {
					ForEach(friends) { friend in
						Button {
							if presentation == .iOS {
								selectedFriend = friend
							} else {
								router.navigate(to: .friends(.friend(id: friend.id)))
							}
						} label: {
							animatedScrollCard(FriendStatusCard(friend: friend))
						}
						.buttonStyle(.plain)
						.onDrag {
							draggedFriend = friend
							return NSItemProvider(object: friend.id.uuidString as NSString)
						}
						.onDrop(
							of: [.text],
							delegate: FriendOrderDropDelegate(
								target: friend,
								draggedFriend: $draggedFriend,
								friends: $friends,
								save: saveFriendOrder
							)
						)
					}
				}
			}
			.padding()
		}
		.refreshable { await refresh() }
	}

	private var friendSearchResults: some View {
		List {
			if isSearching {
				ProgressView()
					.frame(maxWidth: .infinity)
					.listRowBackground(Color.clear)
			} else if searchResults.isEmpty {
				ContentUnavailableView.search(text: searchText)
					.listRowBackground(Color.clear)
			} else {
				ForEach(searchResults) { result in
					FriendSearchRow(result: result)
						.listRowBackground(Image("paper").resizable().scaledToFill())
				}
			}
		}
		.listStyle(.plain)
	}

	private func refresh() async {
		do {
			try await service.refresh()
		} catch {
			PrintError("Friends refresh failed", category: .network, error: error)
		}
	}

	private func search(for value: String) async {
		let query = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard query.count >= 2 else {
			searchResults = []
			isSearching = false
			return
		}
		isSearching = true
		defer {
			if !Task.isCancelled {
				isSearching = false
			}
		}
		do {
			let results = try await service.search(query: query)
			guard !Task.isCancelled else { return }
			searchResults = results
		} catch {
			guard !Task.isCancelled else { return }
			searchResults = []
		}
	}

	private func saveFriendOrder(_ orderedFriends: [FriendSummary]) {
		Task {
			do {
				try await service.reorder(friendIDs: orderedFriends.map(\.friend.id))
			} catch {
				try? await service.refresh()
			}
		}
	}

	private func friendTransitionID(_ friend: FriendSummary) -> String {
		"friend-\(friend.id.uuidString)"
	}
}

private struct FriendOrderDropDelegate: DropDelegate {
	let target: FriendSummary
	@Binding var draggedFriend: FriendSummary?
	@Binding var friends: [FriendSummary]
	let save: ([FriendSummary]) -> Void

	func dropEntered(info _: DropInfo) {
		guard let draggedFriend, draggedFriend != target,
		      let from = friends.firstIndex(of: draggedFriend),
		      let to = friends.firstIndex(of: target)
		else {
			return
		}

		withAnimation(.snappy) {
			friends.move(
				fromOffsets: IndexSet(integer: from),
				toOffset: to > from ? to + 1 : to
			)
		}
	}

	func performDrop(info _: DropInfo) -> Bool {
		defer {
			draggedFriend = nil
		}
		save(friends)
		return true
	}
}

private enum FriendsSheet: String, Identifiable {
	case addFriend
	case requests

	var id: String {
		rawValue
	}

	var transitionID: String {
		"friends-sheet-\(rawValue)"
	}
}
