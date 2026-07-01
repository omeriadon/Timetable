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
	let isShareable: Bool

	private enum CodingKeys: String, CodingKey {
		case id, issuerAccountID, sourceKind, signedDisplayName, authorDisplayName
		case subjects, receivedAt, passUpdatedAt, isDeleted, isShareable
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		issuerAccountID = try container.decode(String.self, forKey: .issuerAccountID)
		sourceKind = try container.decode(SourceKind.self, forKey: .sourceKind)
		signedDisplayName = try container.decode(String.self, forKey: .signedDisplayName)
		authorDisplayName = try container.decodeIfPresent(String.self, forKey: .authorDisplayName)
		subjects = try container.decode([Subject].self, forKey: .subjects)
		receivedAt = try container.decode(Date.self, forKey: .receivedAt)
		passUpdatedAt = try container.decode(Date.self, forKey: .passUpdatedAt)
		isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
		isShareable = try container.decodeIfPresent(Bool.self, forKey: .isShareable) ?? false
	}

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
		isShareable = false
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
		isDeleted: Bool,
		isShareable: Bool = false
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
		self.isShareable = isShareable
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
