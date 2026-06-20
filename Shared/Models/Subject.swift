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
		SubjectEntity(id: id, symbol: symbol, colour: colour, slots: slots)
	}
}

extension Array where Element == Subject {
	func toSubjectEntities() -> [SubjectEntity] {
		map { $0.toSubjectEntity() }
	}
}
