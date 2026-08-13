import Defaults
import SwiftUI

struct FriendsView: View {
	@Default(.friends) private var friends
	@Default(.incomingFriendRequests) private var incomingFriendRequests
	@Default(.hasSeenLocationStatusWhatsNew) private var hasSeenLocationStatusWhatsNew
	@State private var service = FriendService.shared
	@State private var searchText = ""
	@State private var sheet: FriendsSheet?
	@State private var selectedFriend: FriendSummary?
	@State private var isSearchPresented = false
	@FocusState private var isSearchFieldFocused
	@State private var showsArrivalStatistics = false
	@State private var showsLocationStatusSheet = false
	@Namespace private var friendSheetNamespace
	@AccessibilityFocusState private var focusedFriendID: UUID?
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@Environment(\.appPresentation) private var presentation
	@Environment(AppRouter.self) private var router

	var body: some View {
		searchableContent
			.appPaperBackground()
			.animation(.easeInOut, value: filteredFriends.map(\.id))
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
					.labelStyle(.iconOnly)
					.badge(incomingFriendRequests.count)
					.accessibilityValue(incomingFriendRequests.isEmpty ? "No pending requests" : "\(incomingFriendRequests.count) pending requests")
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button("Add friend", systemImage: "person.badge.plus") {
						if presentation == .iOS {
							sheet = .addFriend
						} else {
							router.navigate(to: .friends(.addFriend))
						}
					}
					.labelStyle(.iconOnly)
				}
			}
			.task { await refresh() }
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
					.navigationTransition(
						.zoom(sourceID: friendTransitionID(friend), in: friendSheetNamespace)
					)
					.appPaperPresentation()
			}
			.sheet(isPresented: $showsLocationStatusSheet) {
				LocationStatusWhatsNewSheet {
					showsLocationStatusSheet = false
					hasSeenLocationStatusWhatsNew = true
				}
				.presentationDetents([.large])
				.presentationDragIndicator(.hidden)
				.appPaperPresentation()
			}
			.onAppear {
				if !hasSeenLocationStatusWhatsNew {
					showsLocationStatusSheet = true
				}
			}
			.onChange(of: selectedFriend) { previousFriend, currentFriend in
				guard currentFriend == nil, let previousFriend else {
					return
				}

				Task { @MainActor in
					try? await Task.sleep(for: .milliseconds(100))
					focusedFriendID = previousFriend.id
				}
			}
			.dynamicTypeSize(.medium)
	}

	private var searchableContent: some View {
		friendsList
			.safeAreaInset(edge: .bottom, spacing: 0) {
				FriendsSearchBar(
					text: $searchText,
					isPresented: $isSearchPresented,
					isFocused: $isSearchFieldFocused
				)
			}
	}

	let isPad = UIDevice.current.userInterfaceIdiom == .pad

	private func animatedScrollCard(_ content: some View) -> some View {
		let shouldReduceMotion = reduceMotion

		return content
			.scrollTransition(.animated(.snappy(duration: 0.3))) { card, phase in
				let useFullEffect = shouldReduceMotion || phase.isIdentity || isPad

				return card
					.opacity(useFullEffect ? 1 : 0.65)
					.scaleEffect(useFullEffect ? 1 : 0.96)
			}
	}

	private var friendsList: some View {
		ScrollView {
			let vStack = VStack(spacing: 14) {
				if friends.isEmpty {
					ContentUnavailableView(
						"No Friends Yet",
						systemImage: "person.2.slash",
						description: Text("Search by name to find friends.")
					)
					.padding(.top, 72)
					.transition(.blurReplace)
				} else if filteredFriends.isEmpty {
					ContentUnavailableView.search(text: cleanedSearchText)
						.padding(.top, 72)
						.transition(.blurReplace)
				} else {
					let forEach = ForEach(filteredFriends) { friend in
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
						.accessibilityLabel(friend.friend.displayName)
						.accessibilityHint("Opens \(friend.friend.displayName)'s timetable")
						.accessibilityFocused($focusedFriendID, equals: friend.id)
						.matchedTransitionSource(
							id: friendTransitionID(friend),
							in: friendSheetNamespace
						)
						.transition(.blurReplace)
					}

					LazyVGrid(
						columns: [
							GridItem(.adaptive(minimum: 320, maximum: 520), spacing: 14),
						],
						spacing: 14
					) {
						if #available(anyAppleOS 27, *), cleanedSearchText.isEmpty {
							forEach
								.reorderable()
						} else {
							forEach
						}
					}
				}
			}

			if #available(anyAppleOS 27, *), cleanedSearchText.isEmpty {
				vStack
					.reorderContainer(for: FriendSummary.self) { difference in
						difference.apply(to: &friends)
						saveFriendOrder(friends)
					}
					.padding()
			} else {
				vStack
					.padding()
			}
		}
		.safeAreaBar(edge: .top, alignment: .center, spacing: 10) {
			LocationStatusRow(showsArrivalStatistics: $showsArrivalStatistics)
				.popover(isPresented: $showsArrivalStatistics) {
					PersonalArrivalStatisticsView()
						.presentationCompactAdaptation(.popover)
				}
		}
		.minimizingToolbarOnScrollDown()
		.refreshable {
			await refresh()
		}
	}

	private struct PersonalArrivalStatisticsView: View {
		@State private var statistics: LocationArrivalStatisticsResponse?
		private let weekdayNames = [
			"Monday",
			"Tuesday",
			"Wednesday",
			"Thursday",
			"Friday",
		]

		var body: some View {
			VStack(alignment: .center, spacing: 12) {
				Text("Average arrival")
					.font(.title3)
					.padding(.bottom, 8)

				LabeledContent("Overall", value: formattedAverageArrival)
					.padding(.bottom, 4)

				ForEach(Array(weekdayNames.enumerated()), id: \.offset) { index, day in
					LabeledContent(day, value: averageArrival(for: index))
				}
			}
			.padding()
			.task {
				statistics = try? await LocationStatusStatisticsService.shared.personalArrivalStatistics()
			}
		}

		private var formattedAverageArrival: String {
			guard let seconds = statistics?.averageArrivalSecondsSinceMidnight else {
				return "No data"
			}
			return LocationArrivalTimeFormatter.string(for: seconds)
		}

		private func averageArrival(for weekdayIndex: Int) -> String {
			guard let statistics,
			      statistics.weekdayAverageArrivalSecondsSinceMidnight.indices.contains(weekdayIndex),
			      let seconds = statistics.weekdayAverageArrivalSecondsSinceMidnight[weekdayIndex]
			else {
				return "No data"
			}

			return LocationArrivalTimeFormatter.string(for: seconds)
		}
	}

	private func refresh() async {
		do {
			try await service.refresh()
		} catch {
			PrintError("Friends refresh failed", category: .network, error: error)
		}
	}

	private var cleanedSearchText: String {
		searchText.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var filteredFriends: [FriendSummary] {
		guard !cleanedSearchText.isEmpty else {
			return friends
		}

		return friends.filter { friend in
			friend.friend.displayName.localizedCaseInsensitiveContains(cleanedSearchText)
				|| friend.friend.email.localizedCaseInsensitiveContains(cleanedSearchText)
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

private struct FriendsSearchBar: View {
	@Binding var text: String
	@Binding var isPresented: Bool
	@FocusState.Binding var isFocused: Bool

	@Namespace private var glassNamespace

	var body: some View {
		GlassEffectContainer {
			Group {
				if isPresented {
					HStack(spacing: 10) {
						Image(systemName: "magnifyingglass")
							.foregroundStyle(.secondary)

						TextField("Search by name", text: $text)
							.textFieldStyle(.plain)
							.focused($isFocused)
							.submitLabel(.search)

						Button(role: .cancel) {
							withAnimation(.easeInOut(duration: 0.3)) {
								text = ""
								isPresented = false
								isFocused = false
							}
						} label: {
							Image(systemName: "xmark")
						}
						.accessibilityLabel("Cancel search")
					}
					.padding(15)
					.glassEffect(.regular.interactive(), in: Capsule())
					.glassEffectID("search", in: glassNamespace)

				} else {
					HStack {
						Spacer()

						Button {
							withAnimation(.easeInOut(duration: 0.3)) {
								isPresented = true
							}

							Task { @MainActor in
								isFocused = true
							}
						} label: {
							Label("Search friends", systemImage: "magnifyingglass")
								.labelStyle(.iconOnly)
								.font(.title2)
								.padding(7)
						}
						.buttonBorderShape(.circle)
						.buttonStyle(.glass)
						.glassEffectID("search", in: glassNamespace)
					}
				}
			}
		}
		.animation(.easeInOut(duration: 0.3), value: "\(isPresented)\(isFocused)")
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.frame(maxWidth: .infinity)
		.padding(.bottom, 10)
	}
}

@available(anyAppleOS 27.0, *)
private extension ReorderDifference where CollectionID == ReorderableSingleCollectionIdentifier {
	func apply<C: RangeReplaceableCollection>(to collection: inout C)
		where C.Element: Identifiable,
		C.Element.ID == ItemID
	{
		let moving = Set(sources)
		guard !moving.isEmpty else {
			return
		}

		var moved: [C.Element] = []
		moved.reserveCapacity(moving.count)
		collection.removeAll { element in
			guard moving.contains(element.id) else {
				return false
			}

			moved.append(element)
			return true
		}

		switch destination.position {
			case let .before(id):
				let index = collection.firstIndex { $0.id == id } ?? collection.endIndex
				collection.insert(contentsOf: moved, at: index)
			case .end:
				collection.append(contentsOf: moved)
		}
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
