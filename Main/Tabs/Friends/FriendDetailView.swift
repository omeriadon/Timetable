import Defaults
import DialStylePicker
import SwiftUI

struct FriendDetailView: View {
	let friend: FriendSummary
	let close: () -> Void
	@State private var detail: FriendDetail?
	@State private var service = FriendService.shared
	@State private var selectedTab = FriendDetailTab.main
	@State private var action: FriendAction?
	@State private var showsReportConfirmation = false
	@State private var showsFriendsSinceRequest = false
	@State private var isLoading: Bool
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation

	init(friend: FriendSummary, close: @escaping () -> Void) {
		self.friend = friend
		self.close = close
		let cachedDetail = Defaults[.friendDetails].first(where: { $0.relationshipID == friend.relationshipID })
		_detail = State(initialValue: cachedDetail)
		_isLoading = State(initialValue: cachedDetail == nil)
	}

	private var displayedFriendName: String {
		detail?.friend.displayName ?? friend.friend.displayName
	}

	private var displayedFriendProfile: FriendProfile {
		detail?.friend ?? friend.friend
	}

	private var selectedTabPosition: Binding<FriendDetailTab?> {
		Binding(
			get: { selectedTab },
			set: { newValue in
				if let newValue {
					selectedTab = newValue
				}
			}
		)
	}

	var body: some View {
		NavigationStack {
			Group {
				if isLoading {
					ProgressView()
						.frame(maxWidth: .infinity, minHeight: 180)
				} else if let detail {
					ScrollView(.horizontal) {
						HStack(spacing: 0) {
							ScrollView {
								FriendOverview(
									detail: detail,
									friendName: detail.friend.displayName,
									locationStatus: friend.locationStatus
								)
							}
							.scrollIndicators(.hidden)
							.containerRelativeFrame(.horizontal)
							.id(FriendDetailTab.main)

							FriendWeek(detail: detail)
								.padding(.top, 14)
								.padding(.horizontal, 7)
								.frame(maxHeight: .infinity, alignment: .top)
								.containerRelativeFrame(.horizontal)
								.id(FriendDetailTab.week)

							FriendInfo(
								detail: detail,
								requestFriendsSinceDate: { showsFriendsSinceRequest = true },
								updateLocationNotificationPreferences: updateLocationNotificationPreferences
							)
							.scrollIndicators(.hidden)
							.containerRelativeFrame(.horizontal)
							.id(FriendDetailTab.info)
						}
						.scrollTargetLayout()
					}
					.scrollTargetBehavior(.paging)
					.scrollIndicators(.hidden)
					.scrollPosition(id: selectedTabPosition)
					.animation(.easeInOut(duration: 0.25), value: selectedTab)
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
				} else {
					ContentUnavailableView("Friend Unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.safeAreaBar(edge: .top, spacing: 5) {
				DialStylePicker(selection: $selectedTab) {
					ForEach(FriendDetailTab.allCases) { tab in
						HStack {
							Spacer()
							Label(tab.title, systemImage: tab.symbol)
							Spacer()
						}
						.tag(tab)
						.dialStylePickerGroup("friend-detail-tabs")
					}
				}
				.tint(.brown)
				.padding(.horizontal)
				.frame(height: 36)
				.padding(.bottom, 5)
				.padding(.top)
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.toolbar {
				if presentation == .iOS {
					ToolbarItem(placement: .cancellationAction) {
						Button("Close", systemImage: "xmark", role: .cancel) {
							close()
						}
						.labelStyle(.iconOnly)
					}
				}

				let toolbarItem = ToolbarItem(placement: .principal) {
					HStack {
						FriendAvatar(profile: displayedFriendProfile, size: 44)
						VStack(alignment: .leading, spacing: 0) {
							Text(displayedFriendName)
								.font(.title2)
								.bold()

							Text(displayedFriendProfile.email)
								.foregroundStyle(.tertiary)
								.font(.caption)
						}
					}
				}
				.sharedBackgroundVisibility(.hidden)

				if #available(anyAppleOS 27, *) {
					toolbarItem
						.contentMarginsRemoved()

				} else {
					toolbarItem
				}

				ToolbarItem(placement: .primaryAction) {
					Menu("Friend actions", systemImage: "ellipsis") {
						Button("Remove Friend", systemImage: "person.badge.minus", role: .destructive) {
							action = .remove
						}
						Button("Report", systemImage: "exclamationmark.bubble", role: .destructive) {
							showsReportConfirmation = true
						}
					}
					.labelStyle(.iconOnly)
				}
			}
			.confirmationDialog(action?.title ?? "", isPresented: Binding(
				get: { action != nil },
				set: {
					if !$0 {
						action = nil
					}
				}
			)) {
				if let action {
					Button(action.title, systemImage: action.symbol, role: .destructive) {
						perform(action)
					}
				}
				Button("Cancel", role: .cancel) {}
			} message: {
				Text(action?.message ?? "")
			}
			.alert("Report Friend?", isPresented: $showsReportConfirmation) {
				Button("Cancel", role: .cancel) {}
				Button("Report", role: .destructive) {
					report()
				}
			} message: {
				Text("This sends a report for review. The friend remains visible in your account.")
			}
			.sheet(isPresented: $showsFriendsSinceRequest) {
				if let detail {
					FriendshipDateChangeRequestSheet(
						friendID: detail.friend.id,
						currentDate: detail.acceptedAt,
						close: { showsFriendsSinceRequest = false }
					)
					.presentationDetents([.fraction(0.5)])
					.appPaperPresentation()
				}
			}
			.task { await load() }
		}
	}

	private func load() async {
		defer { isLoading = false }
		do {
			detail = try await service.detail(for: friend.friend.id)
		} catch {
			badges.present(error: error, title: "Unable to load friend")
		}
	}

	private func updateLocationNotificationPreferences(
		_ preferences: Set<LocationNotificationPreference>
	) {
		guard let currentDetail = detail else {
			return
		}

		let previousPreferences = currentDetail.locationNotificationPreferences
		detail = FriendDetail(
			relationshipID: currentDetail.relationshipID,
			friend: currentDetail.friend,
			acceptedAt: currentDetail.acceptedAt,
			timetable: currentDetail.timetable,
			averageArrivalSecondsSinceMidnight: currentDetail.averageArrivalSecondsSinceMidnight,
			weekdayAverageArrivalSecondsSinceMidnight: currentDetail.weekdayAverageArrivalSecondsSinceMidnight,
			locationNotificationPreferences: preferences
		)

		Task {
			do {
				try await service.updateLocationNotificationPreferences(
					for: friend.friend.id,
					preferences: preferences
				)
			} catch {
				detail = FriendDetail(
					relationshipID: currentDetail.relationshipID,
					friend: currentDetail.friend,
					acceptedAt: currentDetail.acceptedAt,
					timetable: currentDetail.timetable,
					averageArrivalSecondsSinceMidnight: currentDetail.averageArrivalSecondsSinceMidnight,
					weekdayAverageArrivalSecondsSinceMidnight: currentDetail.weekdayAverageArrivalSecondsSinceMidnight,
					locationNotificationPreferences: previousPreferences
				)
				badges.present(error: error, title: "Unable to update notifications")
			}
		}
	}

	private func perform(_: FriendAction) {
		Task {
			do {
				try await service.remove(friendID: friend.friend.id)
				close()
			} catch {
				badges.present(error: error, title: "Unable to update friend")
			}
		}
	}

	private func report() {
		Task {
			do {
				try await TimetableDiscoveryService.shared.report(authorID: friend.friend.id)
				badges.addBadge(id: UUID(), title: "Friend reported", priority: 3, view: .success)
			} catch {
				badges.present(error: error, title: "Unable to report friend")
			}
		}
	}
}

private enum FriendDetailTab: CaseIterable, Hashable, Identifiable {
	case main
	case week
	case info

	var id: Self {
		self
	}

	var title: String {
		switch self {
			case .main:
				"Main"
			case .week:
				"Week"
			case .info:
				"Info"
		}
	}

	var symbol: String {
		switch self {
			case .main:
				"person.text.rectangle"
			case .week:
				"calendar"
			case .info:
				"info.circle"
		}
	}
}

private enum FriendAction {
	case remove

	var title: String {
		"Remove Friend"
	}

	var symbol: String {
		"person.badge.minus"
	}

	var message: String {
		"This removes the friend and their timetable from your account."
	}
}
