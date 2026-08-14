import Defaults
import SwiftUI

struct WideRouteDestinationView: View {
	let route: AppRoute
	let showsCloseButton: Bool
	let close: () -> Void
	let closeWideDestination: () -> Void
	@Default(.friends) private var friends

	init(
		route: AppRoute,
		showsCloseButton: Bool = false,
		close: @escaping () -> Void,
		closeWideDestination: @escaping () -> Void
	) {
		self.route = route
		self.showsCloseButton = showsCloseButton
		self.close = close
		self.closeWideDestination = closeWideDestination
	}

	var body: some View {
		Group {
			switch route {
				case .root, .timetable(.root), .friends(.root), .settings(.root), .administration(.root):
					EmptyView()
				case .settings(.appearance):
					AppearanceSettingsView()
				case let .timetable(.subject(_, subjectID, slot)):
					TimetableSubjectInspectorView(subjectID: subjectID, slot: slot)
				case .timetable(.planner), .timetable(.calendarEvent):
					ContentUnavailableView("Timetable Detail", systemImage: "calendar")
				case .friends(.addFriend):
					AddFriendSheet(
						close: close,
						embedsInNavigation: false,
						showsCloseButton: false
					)
				case .friends(.requests):
					FriendRequestsSheet(
						close: close,
						embedsInNavigation: false,
						showsCloseButton: false
					)
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
				case .settings(.feedback):
					FeedbackView(
						close: close,
						embedsInNavigation: false,
						showsCloseButton: false
					)
				case .settings(.about):
					AboutView()
				case .settings(.profileAppearance):
					ProfileAppearanceSheet(close: close)
				case .settings(.navigationPersistence):
					NavigationPersistenceSettingsView()
				case .administration(.statistics):
					AdministrationStatisticsView()
				case .administration(.userReports):
					AdministrationUserReportsView()
				case .administration(.schoolEvents), .administration(.schoolEvent(id: _)):
					AdministrationSchoolEventsView(closeWideDestination: closeWideDestination)
				case .administration(.eventTags), .administration(.eventTag(id: _)), .administration(.eventTagSection(id: _)):
					AdministrationEventTagsView(closeWideDestination: closeWideDestination)
				case let .administration(.calendarEntries(kind)), let .administration(.calendarEntry(kind, _)):
					AdministrationCalendarEntriesView(kind: kind, closeWideDestination: closeWideDestination)
				case .administration(.users), .administration(.user(id: _)):
					AdministrationUsersView(closeWideDestination: closeWideDestination)
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
					MainPlatformAuthenticationView(initialPageID: id)
			}
		}
		.toolbar {
			if showsCloseButton {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", action: close)
						.labelStyle(.iconOnly)
						.accessibilityLabel("Close")
				}
			}
		}
	}
}
