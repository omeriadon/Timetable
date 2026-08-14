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

nonisolated struct AdministrationUserReport: Codable, Identifiable, Sendable {
	let id: UUID
	let reporterID: UUID
	let reporterDisplayName: String?
	let reportedUserID: UUID
	let reportedUserDisplayName: String?
	let action: ModerationAction
	let createdAt: Date?
}

nonisolated struct AdministrationEmailDeliveryRecord: Codable, Identifiable, Sendable {
	let id: UUID
	let recipient: String
	let subject: String
	let body: String
	let status: String
	let failureReason: String?
	let createdAt: Date?
	let updatedAt: Date?
}
