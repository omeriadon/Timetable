import Foundation

enum AppRootDestination: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
	case timetable
	case timetableToday
	case timetableWeek
	case timetablePlanner
	case friends
	case grades
	case settings
	case administration

	var id: String {
		rawValue
	}
}

typealias MainTab = AppRootDestination

enum TimetableRoute: Codable, Hashable, Sendable {
	case root
	case received(id: String)
	case subject(timetableID: String?, subjectID: String, slot: Slot?)
	case planner
	case calendarEvent(id: UUID)
}

enum TimetableSubtab: Int, Codable, CaseIterable, Hashable, Sendable {
	case today
	case week
	case planner
}

enum FriendsRoute: Codable, Hashable, Sendable {
	case root
	case addFriend
	case requests
	case friend(id: UUID)
}

enum SettingsRoute: Codable, Hashable, Sendable {
	case root
	case account
	case updatesAndNotifications
	case tagSubscriptions
	case createdTimetables
	case createdTimetable(id: UUID)
	case receivedTimetables
	case feedback
	case shareAlias
	case about
	case profileAppearance
	case navigationPersistence
}

enum AdministrationRoute: Codable, Hashable, Sendable {
	case root
	case statistics
	case friendshipDateChangeRequests
	case userReports
	case schoolEvents
	case schoolEvent(id: UUID?)
	case eventTags
	case eventTag(id: UUID?)
	case eventTagSection(id: UUID?)
	case calendarEntries(kind: String)
	case calendarEntry(kind: String, id: UUID?)
	case users
	case user(id: UUID?)
	case broadcastNotification
	case broadcastHistory
	case broadcastRecord(id: UUID)
	case administrators
	case serverAccess
	case profileStorage
	case specialBadges
	case specialBadge(id: UUID?)
}

enum AccountRoute: String, Codable, Hashable, Sendable {
	case root
	case authentication
	case profile
}

enum OnboardingRoute: Codable, Hashable, Sendable {
	case page(id: String)
}

enum AppRoute: Codable, Hashable, Sendable {
	case root(AppRootDestination)
	case timetable(TimetableRoute)
	case friends(FriendsRoute)
	case settings(SettingsRoute)
	case administration(AdministrationRoute)
	case account(AccountRoute)
	case onboarding(OnboardingRoute)

	var rootDestination: AppRootDestination {
		switch self {
			case let .root(destination):
				destination
			case .timetable:
				.timetable
			case .friends:
				.friends
			case .settings, .account:
				.settings
			case .administration:
				.administration
			case .onboarding:
				.settings
		}
	}

	var url: URL? {
		AppRouteURLCodec.url(for: self)
	}

	init?(url: URL) {
		guard let route = AppRouteURLCodec.route(from: url) else {
			return nil
		}
		self = route
	}
}
