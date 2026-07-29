import Foundation

nonisolated enum SyncMutationOutcome: String, Codable, Sendable {
	case accepted
	case serverRecordNewer
	case deletedOnServer
	case invalidReferenceDropped
	case authorizationRejected
	case validationRejected
}

nonisolated struct SyncMutationResult: Codable, Sendable {
	let mutationID: UUID
	let recordType: SyncRecordType
	let recordID: UUID?
	let outcome: SyncMutationOutcome
	let serverRevision: Int
	let ownerTimetable: OwnerTimetableResponse?
	let droppedReferenceIDs: [UUID]
	let message: String?
}

nonisolated struct SyncEnvelopeResponse: Codable, Sendable {
	let serverTime: Date
	let requestID: UUID
	let installationID: String
	let results: [SyncMutationResult]
	let tombstones: [SyncTombstone]
	let nextCursor: String?
}
