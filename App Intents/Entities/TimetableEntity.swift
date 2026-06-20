//
//  TimetableEntity.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
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
			self.sharedInfo = SharedInfo(receivedAt: receivedAt, sender: sender)
		}
	}

	var displayRepresentation: DisplayRepresentation {
		let string = {
			if let sharedInfo {
				return "\(sharedInfo.sender)'s Timetable"
			} else {
				return "Your timetable"
			}
		}()

		return DisplayRepresentation(stringLiteral: string)
	}
}

#if !os(watchOS)
extension TimetableEntity: IndexedEntity {}
#endif

struct SharedInfo: Codable, Identifiable, TransientAppEntity {
	var id: String {
		"\(self.sender)\(self.receivedAt.description)"
	}

	static let typeDisplayRepresentation = TypeDisplayRepresentation(stringLiteral: "Owner")
	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: "\(self.sender)'s Timetable")
	}

	var receivedAt: Date
	var sender: String

	init() {
		self.receivedAt = Date()
		self.sender = ""
	}

	init(receivedAt: Date, sender: String) {
		self.receivedAt = receivedAt
		self.sender = sender
	}
}
