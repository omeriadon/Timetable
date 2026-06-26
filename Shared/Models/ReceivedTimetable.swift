//
//  ReceivedTimetable.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import Defaults
import Foundation

typealias ReceivedTimetables = [ReceivedTimetable]
struct ReceivedTimetable: Codable, Defaults.Serializable, Identifiable, Hashable, Equatable {
	var id: String

	var sender: String
	var subjects: [Subject]
	let receivedAt: Date

	init(sender: String, subjects: [Subject], receivedAt: Date) {
		id = UUID().uuidString
		self.sender = sender
		self.subjects = subjects
		self.receivedAt = receivedAt
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
