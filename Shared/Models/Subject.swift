//
//   Subject.swift
//   Shared
//
//   Created by Adon Omeri on 20/6/2026.
//

import Defaults
import Foundation

nonisolated struct Subject: Hashable, Codable, Defaults.Serializable, Identifiable, Equatable {
	var id: String
	var symbol: String
	var colour: RGBAColor
	var slots: [Slot]
	var classroom: Classroom
	var teacher: Teacher

	init(
		id: String,
		symbol: String,
		colour: RGBAColor,
		slots: [Slot],
		classroom: Classroom = .unknown(rawLocation: "Unknown classroom"),
		teacher: Teacher = .unknown(rawNotes: "Unknown teacher")
	) {
		self.id = id
		self.symbol = symbol
		self.colour = colour
		self.slots = slots
		self.classroom = classroom
		self.teacher = teacher
	}

	private enum CodingKeys: String, CodingKey {
		case id, symbol, colour, slots, classroom, teacher
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		symbol = try container.decode(String.self, forKey: .symbol)
		colour = try container.decode(RGBAColor.self, forKey: .colour)
		slots = try container.decode([Slot].self, forKey: .slots)
		classroom = try container.decodeIfPresent(Classroom.self, forKey: .classroom) ?? .unknown(rawLocation: "Unknown classroom")
		teacher = try container.decodeIfPresent(Teacher.self, forKey: .teacher) ?? .unknown(rawNotes: "Unknown teacher")
	}

	func toSubjectEntity(identifier: String? = nil) -> SubjectEntity {
		SubjectEntity(id: identifier ?? id, name: id, symbol: symbol, colour: colour, slots: slots)
	}
}

nonisolated extension [Subject] {
	func toSubjectEntities(prefix: String? = nil) -> [SubjectEntity] {
		map { subject in subject.toSubjectEntity(identifier: prefix.map { "\($0).\(subject.id)" }) }
	}

	func toTimetableEntity() -> TimetableEntity {
		let id: String = map(\.id).joined()

		return TimetableEntity(id: id, subjects: toSubjectEntities())
	}
}
