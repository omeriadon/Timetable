//
//   ReceivedTimetable.swift
//   Shared
//
//   Created by Adon Omeri on 20/6/2026.
//

import Defaults
import Foundation

typealias ReceivedTimetables = [ReceivedTimetable]
nonisolated struct ReceivedTimetable: Codable, Defaults.Serializable, Identifiable, Hashable, Equatable {
	let id: String
	let issuerAccountID: String
	let sourceKind: SourceKind
	let signedDisplayName: String
	let authorDisplayName: String?
	let subjects: [Subject]
	let receivedAt: Date
	let passUpdatedAt: Date
	let isDeleted: Bool

	var sender: String {
		if let override = Defaults[.receivedNameOverrides][id]?
			.trimmingCharacters(in: .whitespacesAndNewlines),
			!override.isEmpty
		{
			return override
		}
		return signedDisplayName
	}

	init(sender: String, subjects: [Subject], receivedAt: Date) {
		let id = UUID().uuidString
		self.id = id
		issuerAccountID = id
		sourceKind = .accountOwner
		signedDisplayName = sender
		authorDisplayName = nil
		self.subjects = subjects
		self.receivedAt = receivedAt
		passUpdatedAt = receivedAt
		isDeleted = false
	}

	init(
		id: String,
		issuerAccountID: String,
		sourceKind: SourceKind,
		signedDisplayName: String,
		authorDisplayName: String?,
		subjects: [Subject],
		receivedAt: Date,
		passUpdatedAt: Date,
		isDeleted: Bool
	) {
		self.id = id
		self.issuerAccountID = issuerAccountID
		self.sourceKind = sourceKind
		self.signedDisplayName = signedDisplayName
		self.authorDisplayName = authorDisplayName
		self.subjects = subjects
		self.receivedAt = receivedAt
		self.passUpdatedAt = passUpdatedAt
		self.isDeleted = isDeleted
	}

	func toTimetableEntity() -> TimetableEntity {
		let entity = TimetableEntity(
			id: id,
			subjects: subjects.toSubjectEntities()
		)
		entity.sharedInfo = SharedInfo(receivedAt: receivedAt, sender: sender)
		return entity
	}
}

extension [ReceivedTimetable] {
	func toTimetableEntities() -> [TimetableEntity] {
		map { $0.toTimetableEntity() }
	}
}
