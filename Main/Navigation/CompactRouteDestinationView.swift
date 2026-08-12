
import Defaults
import SwiftUI

struct CompactRouteDestinationView: View {
	let route: AppRoute

	@Environment(AppRouter.self) private var router
	@Default(.friends) private var friends

	var body: some View {
		switch route {
			case .root:
				EmptyView()
			case .timetable:
				EmptyView()
			case .friends(.root):
				FriendsView()
			case .friends(.addFriend):
				AddFriendSheet(
					close: router.popCurrentRoute,
					embedsInNavigation: false
				)
			case .friends(.requests):
				FriendRequestsSheet(
					close: router.popCurrentRoute,
					embedsInNavigation: false
				)
			case let .friends(.friend(id)):
				if let friend = friends.first(where: { $0.id == id }) {
					FriendDetailView(
						friend: friend,
						close: router.popCurrentRoute
					)
				} else {
					ContentUnavailableView(
						"Friend Unavailable",
						systemImage: "person.crop.circle.badge.exclamationmark"
					)
				}
			case .settings(.root):
				EmptyView()
			case .settings(.account), .account(.root), .account(.profile):
				AccountView()
			case .account(.authentication):
				AccountAuthenticationView(allowsSignUp: true)
			case .settings(.updatesAndNotifications):
				AccountAndSyncSettingsView()
			case .settings(.tagSubscriptions):
				TagSubscriptionsView()
			case .settings(.feedback):
				FeedbackView(
					close: router.popCurrentRoute,
					embedsInNavigation: false
				)
			case .settings(.about):
				AboutView()
			case .settings(.profileAppearance):
				ProfileAppearanceSheet(close: router.popCurrentRoute)
			case .settings(.navigationPersistence):
				NavigationPersistenceSettingsView()
			case .administration(.root):
				AdministrationView()
			case .administration(.statistics):
				AdministrationStatisticsView()
			case .administration(.friendshipDateChangeRequests):
				AdministrationFriendshipDateChangeRequestsView()
			case .administration(.userReports):
				AdministrationUserReportsView()
			case .administration(.schoolEvents), .administration(.schoolEvent(id: _)):
				AdministrationSchoolEventsView(closeWideDestination: nil)
			case .administration(.eventTags),
			     .administration(.eventTag(id: _)),
			     .administration(.eventTagSection(id: _)):
				AdministrationEventTagsView(closeWideDestination: nil)
			case let .administration(.calendarEntries(kind)),
			     let .administration(.calendarEntry(kind, _)):
				AdministrationCalendarEntriesView(kind: kind, closeWideDestination: nil)
			case .administration(.users), .administration(.user(id: _)):
				AdministrationUsersView(closeWideDestination: nil)
			case .administration(.broadcastNotification):
				AdministrationBroadcastNotificationView()
			case .administration(.broadcastHistory), .administration(.broadcastRecord(id: _)):
				AdministrationBroadcastHistoryView()
			case .administration(.emailLog):
				AdministrationEmailLogView()
			case .administration(.administrators):
				AdministrationAdministratorsView()
			case .administration(.serverAccess):
				AdministrationDevelopmentAccessView()
			case .administration(.appVersion):
				AdministrationAppVersionView()
			case .administration(.fontWidthTest):
				AdministrationFontWidthTestView()
			case .administration(.profileStorage):
				AdministrationProfileStorageView()
			case .administration(.specialBadges), .administration(.specialBadge(id: _)):
				AdministrationSpecialBadgesView()
			case let .onboarding(.page(id)):
				OnboardingView()
					.onAppear {
						Defaults[.onboardingPageID] = id
					}
		}
	}
}
