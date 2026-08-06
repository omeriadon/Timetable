import Foundation

nonisolated enum ModerationAction: String, Codable, Hashable, Sendable {
	case pending
	case noAction
	case accountDeleted
	case approved
	case rejected
}

nonisolated struct FriendshipDateChangeRequest: Codable, Sendable {
	let requestedDate: Date
}

nonisolated struct AdministrationModerationResolutionRequest: Codable, Sendable {
	let action: ModerationAction
}

nonisolated struct AdministrationFriendshipDateChangeRequest: Codable, Identifiable, Sendable {
	let id: UUID
	let requesterID: UUID
	let requesterDisplayName: String?
	let requestedDate: Date
	let action: ModerationAction
	let createdAt: Date?
}

nonisolated struct AdministrationUserReport: Codable, Identifiable, Sendable {
	let id: UUID
	let reporterID: UUID
	let reporterDisplayName: String?
	let reportedUserID: UUID
	let reportedUserDisplayName: String?
	let action: ModerationAction
	let createdAt: Date?
}
