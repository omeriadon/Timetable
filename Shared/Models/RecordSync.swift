import Defaults
import Foundation

nonisolated enum SyncRecordType: String, Codable, Defaults.Serializable, Sendable {
	case ownerTimetable
	case privateCalendarEvent
}

nonisolated enum SyncMutationOperation: String, Codable, Defaults.Serializable, Sendable {
	case upsert
	case delete
}

nonisolated struct OwnerTimetableSyncPayload: Codable, Defaults.Serializable, Sendable {
	let subjects: [Subject]
	let isSearchable: Bool
}

nonisolated struct SyncRecordMutation: Codable, Defaults.Serializable, Identifiable, Sendable {
	let mutationID: UUID
	let recordType: SyncRecordType
	let recordID: UUID?
	let operation: SyncMutationOperation
	let baseRevision: Int
	let ownerTimetable: OwnerTimetableSyncPayload?

	var id: UUID {
		mutationID
	}
}

nonisolated struct SyncEnvelopeRequest: Codable, Sendable {
	let requestID: UUID
	let installationID: String
	let mutations: [SyncRecordMutation]
	let cursor: String?
}

nonisolated struct SyncTombstone: Codable, Defaults.Serializable, Sendable {
	let recordType: SyncRecordType
	let recordID: UUID
	let revision: Int
	let deletedAt: Date
}

nonisolated struct SyncRecordRevisions: Codable, Defaults.Serializable, Sendable {
	var values: [String: Int]

	static let empty = SyncRecordRevisions(values: [:])

	func revision(
		for recordType: SyncRecordType,
		recordID: UUID? = nil
	) -> Int {
		values[key(for: recordType, recordID: recordID)] ?? 0
	}

	mutating func setRevision(
		_ revision: Int,
		for recordType: SyncRecordType,
		recordID: UUID? = nil
	) {
		values[key(for: recordType, recordID: recordID)] = revision
	}

	private func key(
		for recordType: SyncRecordType,
		recordID: UUID?
	) -> String {
		[
			recordType.rawValue,
			recordID?.uuidString.lowercased() ?? "singleton",
		].joined(separator: ":")
	}
}
