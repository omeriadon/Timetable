import Foundation

enum ModerationAction: String, Codable, Hashable {
	case pending
	case noAction
	case accountDeleted
	case approved
	case rejected
}

struct FriendshipDateChangeRequest: Codable {
	let requestedDate: Date
}

struct AdministrationModerationResolutionRequest: Codable {
	let action: ModerationAction
}

struct AdministrationFriendshipDateChangeRequest: Codable, Identifiable {
	let id: UUID
	let requesterID: UUID
	let requesterDisplayName: String?
	let requestedDate: Date
	let action: ModerationAction
	let createdAt: Date?
}

struct AdministrationUserReport: Codable, Identifiable {
	let id: UUID
	let reporterID: UUID
	let reporterDisplayName: String?
	let reportedUserID: UUID
	let reportedUserDisplayName: String?
	let action: ModerationAction
	let createdAt: Date?
}
