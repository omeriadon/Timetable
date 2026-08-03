import Defaults
import SwiftUI

struct WideRouteDestinationView: View {
	let route: AppRoute
	@Environment(AppRouter.self) private var router
	@Default(.friends) private var friends

	var body: some View {
		switch route {
			case .root, .timetable(.root), .friends(.root), .settings(.root), .administration(.root):
				EmptyView()
			case let .timetable(.subject(timetableID, subjectID, slot)):
				TimetableSubjectInspectorView(timetableID: timetableID, subjectID: subjectID, slot: slot)
			case .timetable(.planner), .timetable(.calendarEvent), .timetable(.received):
				ContentUnavailableView("Timetable Detail", systemImage: "calendar")
			case .friends(.requests):
				FriendRequestsSheet(close: close)
			case let .friends(.friend(id)):
				if let friend = friends.first(where: { $0.id == id }) {
					FriendDetailView(friend: friend, close: close)
				} else {
					ContentUnavailableView("Friend Unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
				}
			case .settings(.account), .account(.root), .account(.profile):
				AccountView()
			case .account(.authentication):
				AccountAuthenticationView(allowsSignUp: true)
			case .settings(.updatesAndNotifications):
				AccountAndSyncSettingsView()
			case .settings(.tagSubscriptions):
				TagSubscriptionsView()
			case .settings(.feedback):
				FeedbackView()
			case .settings(.about):
				AboutView()
			case .settings(.profileAppearance):
				ProfileAppearanceSheet(close: close)
			case .settings(.navigationPersistence):
				NavigationPersistenceSettingsView()
			case .settings(.createdTimetables), .settings(.createdTimetable(id: _)):
				CreatedTimetablesSettingsView()
			case .settings(.receivedTimetables):
				ReceivedTimetablesView()
			case .administration(.schoolEvents), .administration(.schoolEvent(id: _)):
				AdministrationSchoolEventsView()
			case .administration(.eventTags), .administration(.eventTag(id: _)), .administration(.eventTagSection(id: _)):
				AdministrationEventTagsView()
			case let .administration(.calendarEntries(kind)), let .administration(.calendarEntry(kind, _)):
				AdministrationCalendarEntriesView(kind: kind)
			case .administration(.users), .administration(.user(id: _)):
				AdministrationUsersView()
			case .administration(.broadcastNotification):
				AdministrationBroadcastNotificationView()
			case .administration(.broadcastHistory), .administration(.broadcastRecord(id: _)):
				AdministrationBroadcastHistoryView()
			case .administration(.administrators):
				AdministrationAdministratorsView()
			case .administration(.serverAccess):
				AdministrationDevelopmentAccessView()
			case .administration(.profileStorage):
				AdministrationProfileStorageView()
			case .administration(.specialBadges), .administration(.specialBadge(id: _)):
				AdministrationSpecialBadgesView()
			case let .onboarding(.page(id)):
				MainPlatformAuthenticationView(initialPageID: id)
		}
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Close", systemImage: "xmark", action: close)
			}
		}
		.transition(.opacity)
	}

	private func close() {
		if router.inspectorRoute != nil {
			router.inspectorRoute = nil
		} else if !router.sidebarPath.isEmpty {
			router.sidebarPath.removeLast()
		}
	}
}
