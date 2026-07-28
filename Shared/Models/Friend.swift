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

	var id: UUID {
		userID
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

	var id: UUID {
		relationshipID
	}
}

nonisolated struct FriendDetail: Codable, Hashable, Sendable {
	let relationshipID: UUID
	let friend: FriendProfile
	let acceptedAt: Date
	let timetable: FriendTimetable?
}

nonisolated struct FriendSearchResult: Codable, Identifiable, Hashable, Sendable {
	let profile: FriendProfile
	let relationship: FriendRelationshipState?

	var id: UUID {
		profile.id
	}
}

nonisolated struct CreateFriendRequest: Codable, Sendable {
	let schoolEmail: String
}

nonisolated struct ProfileAppearance: Codable, Defaults.Serializable, Hashable, Sendable {
	let usesMonogram: Bool
	let monogram: String
	let symbol: String
	let font: String
	let colours: [RGBAColor]
	let speed: Double
	let noise: Double

	static let `default` = ProfileAppearance(
		usesMonogram: false,
		monogram: "",
		symbol: "person.fill",
		font: "rounded",
		colours: [
			RGBAColor(hexString: "#6AA7FF"),
			RGBAColor(hexString: "#B06CFF"),
			RGBAColor(hexString: "#FA9DB3"),
		],
		speed: 0.2,
		noise: 64
	)
}

nonisolated struct FriendProfileAppearanceUpdateRequest: Codable, Sendable {
	let appearanceData: Data
}
