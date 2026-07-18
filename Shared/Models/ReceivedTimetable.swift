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
	let importID: String?
	let issuerAccountID: String
	let sourceKind: SourceKind
	let signedDisplayName: String
	let authorDisplayName: String?
	let subjects: [Subject]
	let receivedAt: Date
	let passUpdatedAt: Date
	let contentRevision: Int
	let isDeleted: Bool
	let isShareable: Bool

	private enum CodingKeys: String, CodingKey {
		case id, importID, issuerAccountID, sourceKind, signedDisplayName, authorDisplayName
		case subjects, receivedAt, passUpdatedAt, contentRevision, isDeleted, isShareable
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		importID = try container.decodeIfPresent(String.self, forKey: .importID)
		issuerAccountID = try container.decode(String.self, forKey: .issuerAccountID)
		sourceKind = try container.decode(SourceKind.self, forKey: .sourceKind)
		signedDisplayName = try container.decode(String.self, forKey: .signedDisplayName)
		authorDisplayName = try container.decodeIfPresent(String.self, forKey: .authorDisplayName)
		subjects = try container.decode([Subject].self, forKey: .subjects)
		receivedAt = try container.decode(Date.self, forKey: .receivedAt)
		passUpdatedAt = try container.decode(Date.self, forKey: .passUpdatedAt)
		contentRevision = try container.decodeIfPresent(Int.self, forKey: .contentRevision) ?? 0
		isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
		isShareable = try container.decodeIfPresent(Bool.self, forKey: .isShareable) ?? false
	}

	var sender: String {
		let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? .standard
		if let override = (sharedDefaults.dictionary(forKey: "receivedNameOverrides") as? [String: String])?[id]?
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
		importID = nil
		issuerAccountID = id
		sourceKind = .accountOwner
		signedDisplayName = sender
		authorDisplayName = nil
		self.subjects = subjects
		self.receivedAt = receivedAt
		passUpdatedAt = receivedAt
		contentRevision = 0
		isDeleted = false
		isShareable = false
	}

	init(
		id: String,
		importID: String? = nil,
		issuerAccountID: String,
		sourceKind: SourceKind,
		signedDisplayName: String,
		authorDisplayName: String?,
		subjects: [Subject],
		receivedAt: Date,
		passUpdatedAt: Date,
		contentRevision: Int = 0,
		isDeleted: Bool,
		isShareable: Bool = false
	) {
		self.id = id
		self.importID = importID
		self.issuerAccountID = issuerAccountID
		self.sourceKind = sourceKind
		self.signedDisplayName = signedDisplayName
		self.authorDisplayName = authorDisplayName
		self.subjects = subjects
		self.receivedAt = receivedAt
		self.passUpdatedAt = passUpdatedAt
		self.contentRevision = contentRevision
		self.isDeleted = isDeleted
		self.isShareable = isShareable
	}

	@MainActor
	func toTimetableEntity() -> TimetableEntity {
		let entity = TimetableEntity(
			id: id,
			subjects: subjects.toSubjectEntities(prefix: "subject.received.\(id)")
		)
		entity.sharedInfo = SharedInfo(receivedAt: receivedAt, sender: sender)
		return entity
	}
}

extension [ReceivedTimetable] {
	@MainActor
	func toTimetableEntities() -> [TimetableEntity] {
		map { $0.toTimetableEntity() }
	}
}
