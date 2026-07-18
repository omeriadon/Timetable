//
//   SubjectEntity.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents

#if !os(watchOS)
	import CoreSpotlight
#endif

struct SubjectEntity: Identifiable, AppEntity, SyncableEntity {
	static var defaultQuery = SubjectQuery()

	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Subject")

	init(id: String? = nil, name: String, symbol: String, colour: RGBAColor, slots: [Slot]) {
		self.id = id ?? name
		self.symbol = symbol
		self.colour = colour
		self.slots = slots
		self.name = name
		#if !os(watchOS)
			searchDescription = ""
			searchKeywords = []
		#endif
	}

	init(id: String? = nil, name: String, symbol: String, colour: RGBAColor, slots: [Slot], personName: String? = nil, teacherName: String? = nil, classroomName: String? = nil) {
		self.init(id: id, name: name, symbol: symbol, colour: colour, slots: slots)
		self.personName = personName
		self.teacherName = teacherName
		self.classroomName = classroomName
		#if !os(watchOS)
			searchDescription = [personName, teacherName, classroomName].compactMap(\.self).joined(separator: " — ")
			searchKeywords = [name, personName, teacherName, classroomName].compactMap(\.self)
		#endif
	}

	var id: String

	@Property(title: "Subject Name")
	var name: String

	var symbol: String

	var colour: RGBAColor

	var slots: [Slot]

	var personName: String?
	var teacherName: String?
	var classroomName: String?

	#if !os(watchOS)
		@Property(identifier: "searchDescription", title: "Search Description", indexingKey: \CSSearchableItemAttributeSet.contentDescription)
		var searchDescription: String
		@Property(identifier: "searchKeywords", title: "Search Keywords")
		var searchKeywords: [String]
	#endif

	var displayRepresentation: DisplayRepresentation {
		let context = personName.map { "\($0) — \(name)" } ?? name
		return DisplayRepresentation(stringLiteral: context)
	}
}

#if !os(watchOS)
	extension SubjectEntity: IndexedEntity {}
#endif
