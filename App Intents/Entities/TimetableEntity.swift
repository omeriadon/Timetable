//
//   TimetableEntity.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Foundation

#if !os(watchOS)
	import CoreSpotlight
#endif

struct TimetableEntity: Identifiable, AppEntity, SyncableEntity {
	static var defaultQuery = TimetableQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Timetable")

	var id: String

	@Property(title: "Subjects")
	var subjects: [SubjectEntity]

	#if !os(watchOS)
		@Property(identifier: "searchDescription", title: "Search Description", indexingKey: \CSSearchableItemAttributeSet.contentDescription)
		var searchDescription: String
		@Property(identifier: "searchKeywords", title: "Search Keywords")
		var searchKeywords: [String]
		@Property(identifier: "contentURL", title: "Content URL", indexingKey: \CSSearchableItemAttributeSet.contentURL)
		var contentURL: URL?
	#endif

	init(id: String, subjects: [SubjectEntity]) {
		self.id = id
		self.subjects = subjects
		#if !os(watchOS)
			searchDescription = ""
			searchKeywords = []
			contentURL = nil
		#endif
		#if !os(watchOS)
			let names = subjects.map(\.name)
			searchDescription = "\(subjects.count) subjects" + (names.isEmpty ? "" : ": \(names.prefix(8).joined(separator: ", "))")
			searchKeywords = names
			contentURL = AppRoute.timetable(.root).url
		#endif
	}

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: "Your timetable")
	}
}

#if !os(watchOS)
	extension TimetableEntity: IndexedEntity {}
#endif
