//
//   AccountDTOs.swift
//   App Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation

nonisolated struct TokenResponse: Codable {
	let accessToken: String
	let refreshToken: String
	let user: UserProfileResponse
}

nonisolated struct UserProfileResponse: Codable {
	let id: UUID
	let email: String?
	let displayName: String
	let createdAt: Date?
	let authority: AccountAuthority
	let appearance: ProfileAppearance
	let photo: ProfilePhotoMetadata?
	let badges: [ProfileBadge]
	let revision: Int

	private enum CodingKeys: String, CodingKey {
		case id
		case email
		case displayName
		case createdAt
		case authority
		case appearance
		case photo
		case badges
		case revision
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		email = try container.decodeIfPresent(String.self, forKey: .email)
		displayName = try container.decode(String.self, forKey: .displayName)
		createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
		authority = try container.decodeIfPresent(AccountAuthority.self, forKey: .authority) ?? .user
		appearance = try container.decodeIfPresent(ProfileAppearance.self, forKey: .appearance) ?? .default
		photo = try container.decodeIfPresent(ProfilePhotoMetadata.self, forKey: .photo)
		let serverBadges = try container.decodeIfPresent([ProfileBadge].self, forKey: .badges) ?? []
		let authorityBadge = BuiltInProfileBadgeConfiguration.badge(for: authority).map { [$0] } ?? []
		badges = serverBadges.filter { BuiltInProfileBadgeConfiguration.authority(for: $0.id) == nil } + authorityBadge
		revision = try container.decodeIfPresent(Int.self, forKey: .revision) ?? 0
	}
}

nonisolated struct UpdateProfileRequest: Codable {
	let displayName: String?
	let email: String?
	let baseRevision: Int
}

nonisolated struct SchoolCalendarResponse: Codable, Sendable {
	let termRanges: [SchoolCalendarDateRange]
	let skippedDates: [SchoolCalendarNamedDate]

	var projection: SchoolCalendarProjection {
		SchoolCalendarProjection(termRanges: termRanges, skippedDates: skippedDates)
	}
}

nonisolated struct CalendarEventsResponse: Codable, Sendable {
	let globalEvents: [CalendarEvent]
	let privateEvents: [CalendarEvent]
	let canManageGlobalEvents: Bool

	var projection: CalendarEventsProjection {
		CalendarEventsProjection(globalEvents: globalEvents, privateEvents: privateEvents, canManageGlobalEvents: canManageGlobalEvents)
	}
}

nonisolated struct CreateCalendarEventRequest: Codable, Sendable {
	let id: UUID?
	let title: String
	let notes: String?
	let symbol: String
	let date: SchoolCalendarDate
	let tagIDs: [UUID]
	let baseRevision: Int?

	init(
		id: UUID? = nil,
		title: String,
		notes: String?,
		symbol: String,
		date: SchoolCalendarDate,
		tagIDs: [UUID] = [],
		baseRevision: Int? = nil
	) {
		self.id = id
		self.title = title
		self.notes = notes
		self.symbol = symbol
		self.date = date
		self.tagIDs = tagIDs
		self.baseRevision = baseRevision
	}

	func withSyncMetadata(
		id: UUID,
		baseRevision: Int
	) -> CreateCalendarEventRequest {
		CreateCalendarEventRequest(
			id: id,
			title: title,
			notes: notes,
			symbol: symbol,
			date: date,
			tagIDs: tagIDs,
			baseRevision: baseRevision
		)
	}
}

nonisolated struct EventTagSubscriptionResponse: Codable, Sendable {
	let tagIDs: [UUID]
	let droppedTagIDs: [UUID]

	private enum CodingKeys: String, CodingKey {
		case tagIDs
		case droppedTagIDs
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		tagIDs = try container.decode([UUID].self, forKey: .tagIDs)
		droppedTagIDs = try container.decodeIfPresent(
			[UUID].self,
			forKey: .droppedTagIDs
		) ?? []
	}
}

nonisolated struct EventTagSubscriptionUpdateRequest: Codable, Sendable {
	let tagIDs: [UUID]
}

nonisolated struct AdministrationDashboardResponse: Codable, Sendable {
	let isAdmin: Bool
	let authority: AccountAuthority
	let pendingModerationCount: Int

	private enum CodingKeys: String, CodingKey {
		case isAdmin
		case authority
		case pendingModerationCount
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		isAdmin = try container.decode(Bool.self, forKey: .isAdmin)
		authority = try container.decodeIfPresent(AccountAuthority.self, forKey: .authority) ?? .user
		pendingModerationCount = try container.decodeIfPresent(Int.self, forKey: .pendingModerationCount) ?? 0
	}
}

nonisolated struct AdministrationUserResponse: Codable, Identifiable, Sendable, Equatable {
	let id: UUID
	let displayName: String
	let email: String?
	let createdAt: Date?
	let authority: AccountAuthority
	let appearance: ProfileAppearance
	let photo: ProfilePhotoMetadata?
	let badges: [ProfileBadge]

	private enum CodingKeys: String, CodingKey {
		case id
		case displayName
		case email
		case createdAt
		case authority
		case appearance
		case photo
		case badges
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		displayName = try container.decode(String.self, forKey: .displayName)
		email = try container.decodeIfPresent(String.self, forKey: .email)
		createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
		authority = try container.decodeIfPresent(AccountAuthority.self, forKey: .authority) ?? .user
		appearance = try container.decodeIfPresent(ProfileAppearance.self, forKey: .appearance) ?? .default
		photo = try container.decodeIfPresent(ProfilePhotoMetadata.self, forKey: .photo)
		let serverBadges = try container.decodeIfPresent([ProfileBadge].self, forKey: .badges) ?? []
		let authorityBadge = BuiltInProfileBadgeConfiguration.badge(for: authority).map { [$0] } ?? []
		badges = serverBadges.filter { BuiltInProfileBadgeConfiguration.authority(for: $0.id) == nil } + authorityBadge
	}
}

nonisolated struct AdministrationUserAuthorityUpdateRequest: Codable, Sendable {
	let authority: AccountAuthority
}

nonisolated struct AdministrationSpecialBadgeResponse: Codable, Identifiable, Sendable, Equatable {
	let id: UUID
	let symbol: String
	let backgroundColor: RGBAColor?
	let symbolColor: RGBAColor?
	let priority: Int
	let accessibilityLabel: String
	let assignedUserIDs: [UUID]
}

nonisolated struct AdministrationSpecialBadgeRequest: Codable, Sendable {
	let symbol: String
	let backgroundColor: RGBAColor?
	let symbolColor: RGBAColor?
	let priority: Int
	let accessibilityLabel: String
}

nonisolated struct AdministrationSpecialBadgeAssignmentsRequest: Codable, Sendable {
	let userIDs: [UUID]
}

nonisolated struct AdministrationSpecialBadgeOrderRequest: Codable, Sendable {
	let badgeIDs: [UUID]
}

nonisolated struct ServerAccessModeUpdateRequest: Codable, Sendable {
	let developmentAccessOnly: Bool
}

nonisolated struct ServerAccessModeResponse: Codable, Sendable {
	let developmentAccessOnly: Bool
}

nonisolated struct ProfileStorageQuotaResponse: Codable, Sendable {
	let storedBytes: Int64
	let reservedBytes: Int64
	let storageLimitBytes: Int64
	let monthlyOperations: Int
	let monthlyOperationLimit: Int
	let monthlyWriteCutoff: Int
	let writesDisabled: Bool
	let reconciledStoredBytes: Int64?
	let reconciliationWarning: Bool?
	let reconciledAt: Date?
}

nonisolated struct AdministrationEventTagCatalogueResponse: Codable, Sendable {
	let sections: [AdministrationEventTagSection]
}

nonisolated struct AdministrationEventTagSection: Codable, Identifiable, Sendable {
	let id: UUID
	let category: AdministrationEventTagCategory
	let displayName: String
	let sortOrder: Int
	let isArchived: Bool
	let revision: Int
	let tags: [AdministrationEventTag]
}

nonisolated struct AdministrationEventTag: Codable, Identifiable, Sendable {
	let id: UUID
	let sectionID: UUID
	let slug: String
	let displayName: String
	let category: AdministrationEventTagCategory
	let symbol: String?
	let colorHex: String?
	let sortOrder: Int
	let isArchived: Bool
	let revision: Int
	let associatedNames: [String]
}

nonisolated struct AdministrationEventTagRequest: Codable, Sendable {
	let sectionID: UUID
	let slug: String
	let displayName: String
	let symbol: String?
	let colorHex: String?
	let sortOrder: Int
	let isArchived: Bool
	let associatedNames: [String]
}

nonisolated struct AdministrationEventTagOrderRequest: Codable, Sendable {
	let tagIDs: [UUID]
}

nonisolated struct AdministrationEventTagSectionCreateRequest: Codable, Sendable {
	let category: AdministrationEventTagCategory
	let displayName: String
	let sortOrder: Int
}

nonisolated struct AdministrationEventTagSectionUpdateRequest: Codable, Sendable {
	let displayName: String
	let sortOrder: Int
	let isArchived: Bool
}

nonisolated struct AdministrationUserCreateRequest: Codable, Sendable {
	let displayName: String
	let email: String
	let password: String
}

nonisolated struct AdministrationUserUpdateRequest: Codable, Sendable {
	let displayName: String
	let email: String
	let password: String?
}

nonisolated struct AdministrationUserDetailResponse: Codable, Sendable {
	let rawData: String
}

nonisolated struct AdministrationCalendarEntry: Codable, Identifiable, Sendable {
	let id: UUID
	let kind: String
	let label: String
	let startDate: SchoolCalendarDate
	let endDate: SchoolCalendarDate?
}

nonisolated struct AdministrationCalendarEntryRequest: Codable, Sendable {
	let kind: String
	let label: String
	let startDate: SchoolCalendarDate
	let endDate: SchoolCalendarDate?
}

nonisolated struct BroadcastNotificationRequest: Codable, Sendable {
	let title: String
	let subtitle: String?
	let body: String?
}

nonisolated struct BroadcastNotificationResponse: Codable, Sendable {
	let id: UUID?
	let eligibleDeviceCount: Int
	let deliveredDeviceCount: Int
	let invalidatedDeviceCount: Int
	let failedDeviceCount: Int
}

nonisolated enum BroadcastNotificationDeliveryState: String, Codable, Sendable {
	case pending
	case completed
	case failed
}

nonisolated struct BroadcastNotificationHistoryResponse: Codable, Identifiable, Sendable {
	let id: UUID
	let senderEmail: String
	let senderAuthority: AccountAuthority
	let title: String
	let subtitle: String?
	let body: String?
	let eligibleDeviceCount: Int
	let deliveredDeviceCount: Int
	let invalidatedDeviceCount: Int
	let failedDeviceCount: Int
	let deliveryState: BroadcastNotificationDeliveryState
	let isDeleted: Bool
	let failureSummary: String?
	let createdAt: Date?

	private enum CodingKeys: String, CodingKey {
		case id
		case senderEmail
		case senderAuthority
		case title
		case subtitle
		case body
		case eligibleDeviceCount
		case deliveredDeviceCount
		case invalidatedDeviceCount
		case failedDeviceCount
		case deliveryState
		case isDeleted
		case failureSummary
		case createdAt
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		senderEmail = try container.decode(String.self, forKey: .senderEmail)
		senderAuthority = try container.decode(AccountAuthority.self, forKey: .senderAuthority)
		title = try container.decode(String.self, forKey: .title)
		subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
		body = try container.decodeIfPresent(String.self, forKey: .body)
		eligibleDeviceCount = try container.decode(Int.self, forKey: .eligibleDeviceCount)
		deliveredDeviceCount = try container.decode(Int.self, forKey: .deliveredDeviceCount)
		invalidatedDeviceCount = try container.decode(Int.self, forKey: .invalidatedDeviceCount)
		failedDeviceCount = try container.decode(Int.self, forKey: .failedDeviceCount)
		deliveryState = try container.decode(BroadcastNotificationDeliveryState.self, forKey: .deliveryState)
		isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
		failureSummary = try container.decodeIfPresent(String.self, forKey: .failureSummary)
		createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
	}
}

nonisolated struct NotificationSettingsUpdateRequest: Codable, Sendable {
	let notificationsEnabled: Bool
	let broadcastNotificationsEnabled: Bool
	let notificationLeadTimes: Set<NotificationLeadTime>
	let breakToPeriodNotificationLeadTimes: Set<NotificationLeadTime>
	let eventNotificationSchedules: Set<EventNotificationSchedule>
	let serverRevision: Int

	init(_ settings: AccountSettings) {
		notificationsEnabled = settings.notificationsEnabled
		broadcastNotificationsEnabled = settings.broadcastNotificationsEnabled
		notificationLeadTimes = settings.notificationLeadTimes
		breakToPeriodNotificationLeadTimes = settings.breakToPeriodNotificationLeadTimes
		eventNotificationSchedules = settings.eventNotificationSchedules
		serverRevision = settings.serverRevision
	}
}

nonisolated struct OwnerTimetableUpdateRequest: Codable {
	let subjects: [Subject]
	let expectedRevision: Int?
	var isSearchable: Bool? = nil
}

nonisolated struct OwnerTimetableVisibilityUpdateRequest: Codable {
	let isSearchable: Bool
}

nonisolated struct OwnerTimetableResponse: Codable, Sendable {
	let id: UUID?
	let subjects: [Subject]
	let revision: Int
	let updatedAt: Date?
	let isSearchable: Bool

	private enum CodingKeys: String, CodingKey { case id, subjects, revision, updatedAt, isSearchable }

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decodeIfPresent(UUID.self, forKey: .id)
		subjects = try container.decode([Subject].self, forKey: .subjects)
		revision = try container.decode(Int.self, forKey: .revision)
		updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
		isSearchable = try container.decodeIfPresent(Bool.self, forKey: .isSearchable) ?? true
	}
}

nonisolated struct TimetableSearchResult: Codable, Identifiable, Hashable {
	let id: UUID
	let title: String
	let authorAccountID: UUID
	let authorDisplayName: String
	let sourceKind: SourceKind
	let confidence: Double
}

nonisolated struct CreatedTimetableUpdateRequest: Codable {
	let title: String
	let subjects: [Subject]
	let isSearchable: Bool
}

nonisolated struct ReportUserRequest: Codable {
	let reportedAccountID: String
}

nonisolated struct FeedbackRequest: Codable {
	let category: String
	let message: String
}

nonisolated struct RegisterUserDeviceRequest: Codable {
	let installationID: String
	let platform: String
	let osMajorVersion: Int
	let apnsToken: String
	/// true when the token is from a debug/sandbox build.
	let isDebug: Bool
}

nonisolated struct RemoveUserDeviceRequest: Codable {
	let installationID: String
	let platform: String
}

nonisolated struct UserDeviceResponse: Codable {
	let installationID: String
	let platform: String
	let isDebug: Bool
	let lastSeenAt: Date
}

nonisolated struct LiveActivityPushToStartTokenRequest: Codable {
	let installationID: String
	let token: String
	let isDebug: Bool
}

nonisolated struct RemoveLiveActivityTokenRequest: Codable {
	let installationID: String
}

nonisolated struct LiveActivityUpdateTokenRequest: Codable {
	let installationID: String
	let token: String
	let isDebug: Bool
}

nonisolated struct ReconcileLiveActivityRequest: Codable {
	let installationID: String
	let activeActivityKeys: [String]
}

nonisolated struct ReconcileLiveActivityResponse: Codable {
	let started: Bool
}

nonisolated struct TestNotificationResponse: Codable {
	let deliveredDeviceCount: Int
}

extension AccountProfile {
	init(_ response: UserProfileResponse) {
		id = response.id.uuidString
		email = response.email
		displayName = response.displayName
		createdAt = response.createdAt
		authority = response.authority
		appearance = response.appearance
		photo = response.photo
		badges = response.badges
		revision = response.revision
	}
}
