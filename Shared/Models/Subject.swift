//
//  Subject.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import Defaults
import Foundation

struct Subject: Hashable, Codable, Defaults.Serializable, Identifiable, Equatable {
	var id: String
	var symbol: String
	var colour: RGBAColor
	var slots: [Slot]

	func toSubjectEntity() -> SubjectEntity {
		SubjectEntity(name: id, symbol: symbol, colour: colour, slots: slots)
	}
}

extension Array where Element == Subject {
	func toSubjectEntities() -> [SubjectEntity] {
		map { $0.toSubjectEntity() }
	}

	func toTimetableEntity() -> TimetableEntity {
		let id: String = map { $0.id }.joined()

		return TimetableEntity(id: id, subjects: toSubjectEntities())
	}
}
