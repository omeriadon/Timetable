//
//  Subject.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct SubjectEntity: Hashable, Identifiable, Equatable, AppEntity {
	static var defaultQuery = SubjectQuery()

	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Subject")

	init(id: String, symbol: String, colour: RGBAColor, slots: [Slot]) {
		self._id = Property(title: LocalizedStringResource(stringLiteral: id))
		self.symbol = symbol
		self.colour = colour
		self.slots = slots
	}

	@Property(title: "Subject Name")
	var id: String

	var symbol: String

	var colour: RGBAColor

	var slots: [Slot]

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: id)
	}

	static func == (lhs: SubjectEntity, rhs: SubjectEntity) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}
