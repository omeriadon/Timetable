import Defaults
import Foundation

nonisolated enum FriendRelationshipState: String, Codable, Sendable {
	case pendingOutgoing
	case pendingIncoming
	case friends
}

nonisolated struct FriendProfile: Codable, Defaults.Serializable, Identifiable, Hashable, Sendable {
	let userID: UUID
	let displayName: String
	let email: String?
	let appearanceData: Data?
	let appearance: ProfileAppearance?
	let photo: ProfilePhotoMetadata?
	let badges: [ProfileBadge]
	let revision: Int

	var id: UUID {
		userID
	}

	init(
		userID: UUID,
		displayName: String,
		email: String?,
		appearanceData: Data?,
		appearance: ProfileAppearance? = nil,
		photo: ProfilePhotoMetadata? = nil,
		badges: [ProfileBadge] = [],
		revision: Int = 0
	) {
		self.userID = userID
		self.displayName = displayName
		self.email = email
		self.appearanceData = appearanceData
		self.appearance = appearance
		self.photo = photo
		self.badges = badges
		self.revision = revision
	}

	private enum CodingKeys: String, CodingKey {
		case userID
		case displayName
		case email
		case appearanceData
		case appearance
		case photo
		case badges
		case revision
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		userID = try container.decode(UUID.self, forKey: .userID)
		displayName = try container.decode(String.self, forKey: .displayName)
		email = try container.decodeIfPresent(String.self, forKey: .email)
		appearanceData = try container.decodeIfPresent(Data.self, forKey: .appearanceData)
		appearance = try container.decodeIfPresent(ProfileAppearance.self, forKey: .appearance)
		photo = try container.decodeIfPresent(ProfilePhotoMetadata.self, forKey: .photo)
		badges = try container.decodeIfPresent([ProfileBadge].self, forKey: .badges) ?? []
		revision = try container.decodeIfPresent(Int.self, forKey: .revision) ?? 0
	}
}

nonisolated struct FriendTimetable: Codable, Defaults.Serializable, Hashable, Sendable {
	let title: String
	let subjects: [Subject]
	let updatedAt: Date?
}

nonisolated struct FriendSummary: Codable, Defaults.Serializable, Identifiable, Hashable, Sendable {
	let relationshipID: UUID
	let friend: FriendProfile
	let state: FriendRelationshipState
	let requestedAt: Date
	let acceptedAt: Date?
	let timetable: FriendTimetable?
	let locationStatus: LocationStatusItem?

	var id: UUID {
		relationshipID
	}

	private enum CodingKeys: String, CodingKey {
		case relationshipID
		case friend
		case state
		case requestedAt
		case acceptedAt
		case timetable
		case locationStatus
	}

	init(
		relationshipID: UUID,
		friend: FriendProfile,
		state: FriendRelationshipState,
		requestedAt: Date,
		acceptedAt: Date?,
		timetable: FriendTimetable?,
		locationStatus: LocationStatusItem?
	) {
		self.relationshipID = relationshipID
		self.friend = friend
		self.state = state
		self.requestedAt = requestedAt
		self.acceptedAt = acceptedAt
		self.timetable = timetable
		self.locationStatus = locationStatus
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		relationshipID = try container.decode(UUID.self, forKey: .relationshipID)
		friend = try container.decode(FriendProfile.self, forKey: .friend)
		state = try container.decode(FriendRelationshipState.self, forKey: .state)
		requestedAt = try container.decode(Date.self, forKey: .requestedAt)
		acceptedAt = try container.decodeIfPresent(Date.self, forKey: .acceptedAt)
		timetable = try container.decodeIfPresent(FriendTimetable.self, forKey: .timetable)
		locationStatus = try container.decodeIfPresent(LocationStatusItem.self, forKey: .locationStatus)
	}
}

nonisolated struct FriendRequestSnapshot: Sendable {
	let incoming: [FriendSummary]
	let outgoing: [FriendSummary]
}

nonisolated struct FriendDetail: Codable, Defaults.Serializable, Hashable, Sendable {
	let relationshipID: UUID
	let friend: FriendProfile
	let acceptedAt: Date
	let timetable: FriendTimetable?
	let averageArrivalSecondsSinceMidnight: Double?
	let locationNotificationPreferences: Set<LocationNotificationPreference>

	init(
		relationshipID: UUID,
		friend: FriendProfile,
		acceptedAt: Date,
		timetable: FriendTimetable?,
		averageArrivalSecondsSinceMidnight: Double?,
		locationNotificationPreferences: Set<LocationNotificationPreference> = []
	) {
		self.relationshipID = relationshipID
		self.friend = friend
		self.acceptedAt = acceptedAt
		self.timetable = timetable
		self.averageArrivalSecondsSinceMidnight = averageArrivalSecondsSinceMidnight
		self.locationNotificationPreferences = locationNotificationPreferences
	}

	private enum CodingKeys: String, CodingKey {
		case relationshipID
		case friend
		case acceptedAt
		case timetable
		case averageArrivalSecondsSinceMidnight
		case locationNotificationPreferences
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		relationshipID = try container.decode(UUID.self, forKey: .relationshipID)
		friend = try container.decode(FriendProfile.self, forKey: .friend)
		acceptedAt = try container.decode(Date.self, forKey: .acceptedAt)
		timetable = try container.decodeIfPresent(FriendTimetable.self, forKey: .timetable)
		averageArrivalSecondsSinceMidnight = try container.decodeIfPresent(
			Double.self,
			forKey: .averageArrivalSecondsSinceMidnight
		)
		locationNotificationPreferences = try container.decodeIfPresent(
			Set<LocationNotificationPreference>.self,
			forKey: .locationNotificationPreferences
		) ?? []
	}
}

nonisolated struct FriendSearchResult: Codable, Identifiable, Hashable, Sendable {
	let profile: FriendProfile
	let relationship: FriendRelationshipState?

	var id: UUID {
		profile.id
	}
}

nonisolated struct CreateFriendRequest: Codable, Sendable {
	let userID: UUID
}

nonisolated struct FriendOrderUpdateRequest: Codable, Sendable {
	let friendIDs: [UUID]
}

nonisolated struct FriendProfileAppearanceUpdateRequest: Codable, Sendable {
	let appearance: ProfileAppearance
	let baseRevision: Int
}
