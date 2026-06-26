//
//  SubjectEntity.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents

struct SubjectEntity: Identifiable, AppEntity, SyncableEntity {
	static var defaultQuery = SubjectQuery()

	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Subject")

	init(name: String, symbol: String, colour: RGBAColor, slots: [Slot]) {
		id = name
		self.symbol = symbol
		self.colour = colour
		self.slots = slots
		self.name = name
	}

	var id: String

	@Property(title: "Subject Name")
	var name: String

	var symbol: String

	var colour: RGBAColor

	var slots: [Slot]

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: id)
	}
}

#if !os(watchOS)
	extension SubjectEntity: IndexedEntity {}
#endif
