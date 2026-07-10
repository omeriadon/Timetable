//
//   TimetableEntity.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents

struct TimetableEntity: Identifiable, AppEntity, SyncableEntity {
	static var defaultQuery = TimetableQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Timetable")

	var id: String

	@Property(title: "Subjects")
	var subjects: [SubjectEntity]

	@Property(title: "Shared Info")
	var sharedInfo: SharedInfo?

	init(id: String, subjects: [SubjectEntity], sender: String? = nil, receivedAt: Date? = nil) {
		self.id = id
		self.subjects = subjects
		if let sender, let receivedAt {
			sharedInfo = SharedInfo(receivedAt: receivedAt, sender: sender)
		}
	}

	var displayRepresentation: DisplayRepresentation {
		let string = if let sharedInfo {
			"\(sharedInfo.sender)'s Timetable"
		} else {
			"Your timetable"
		}

		return DisplayRepresentation(stringLiteral: string)
	}
}

#if !os(watchOS)
	extension TimetableEntity: IndexedEntity {}
#endif

nonisolated struct SharedInfo: Codable, Identifiable, TransientAppEntity {
	var id: String {
		"\(sender)\(receivedAt.description)"
	}

	static let typeDisplayRepresentation = TypeDisplayRepresentation(stringLiteral: "Owner")
	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: "\(sender)'s Timetable")
	}

	var receivedAt: Date
	var sender: String

	init() {
		receivedAt = Date()
		sender = ""
	}

	init(receivedAt: Date, sender: String) {
		self.receivedAt = receivedAt
		self.sender = sender
	}
}
