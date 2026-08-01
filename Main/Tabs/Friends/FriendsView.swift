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
	@Namespace private var sheetNamespace

	var body: some View {
		NavigationStack {
			Group {
				if searchText.isEmpty {
					friendsList
				} else {
					friendSearchResults
				}
			}
			.scrollEdgeEffect()
			.appNavigationTitle("Friends", accent: true)
			.toolbar {
				ToolbarItemGroup(placement: .topBarTrailing) {
					Button("Friend requests", systemImage: incomingFriendRequests.isEmpty ? "bell" : "bell.badge") {
						sheet = .requests
					}
					.matchedTransitionSource(id: FriendsSheet.requests.transitionID, in: sheetNamespace)
					.accessibilityValue(incomingFriendRequests.isEmpty ? "No pending requests" : "\(incomingFriendRequests.count) pending requests")

					Button("Add friend", systemImage: "person.badge.plus") {
						sheet = .addFriend
					}
					.matchedTransitionSource(id: FriendsSheet.addFriend.transitionID, in: sheetNamespace)
				}
			}
			.searchable(text: $searchText, prompt: "Search with a school email")
			.task { await refresh() }
			.onChange(of: searchText) { _, value in
				Task { await search(for: value) }
			}
			.sheet(item: $sheet) { sheet in
				switch sheet {
					case .addFriend:
						AddFriendSheet()
							.navigationTransition(.zoom(sourceID: sheet.transitionID, in: sheetNamespace))
							.presentationDetents([.large])
							.presentationDragIndicator(.hidden)
					case .requests:
						FriendRequestsSheet()
							.navigationTransition(.zoom(sourceID: sheet.transitionID, in: sheetNamespace))
							.presentationDetents([.fraction(0.6), .large])
							.presentationDragIndicator(.hidden)
				}
			}
			.sheet(item: $selectedFriend) { friend in
				FriendDetailView(friend: friend)
					.navigationTransition(
						.zoom(
							sourceID: friendTransitionID(friend),
							in: sheetNamespace
						)
					)
			}
		}
		.dynamicTypeSize(.medium)
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
							selectedFriend = friend
						} label: {
						FriendStatusCard(friend: friend)
							.scrollTransition(.animated(.snappy(duration: 0.3))) { card, phase in
								card
									.opacity(reduceMotion || phase.isIdentity ? 1 : 0.65)
									.scaleEffect(reduceMotion || phase.isIdentity ? 1 : 0.96)
							}
						}
						.buttonStyle(.plain)
						.matchedTransitionSource(
							id: friendTransitionID(friend),
							in: sheetNamespace
						)
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
		let schoolEmail = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard schoolEmail.contains("@") else {
			searchResults = []
			return
		}
		isSearching = true
		defer { isSearching = false }
		do {
			searchResults = try await service.search(schoolEmail: schoolEmail)
		} catch {
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
