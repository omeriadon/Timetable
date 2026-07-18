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

	@Property(title: "Shared Info")
	var sharedInfo: SharedInfo?

	#if !os(watchOS)
		@Property(identifier: "searchDescription", title: "Search Description", indexingKey: \CSSearchableItemAttributeSet.contentDescription)
		var searchDescription: String
		@Property(identifier: "searchKeywords", title: "Search Keywords")
		var searchKeywords: [String]
		@Property(identifier: "contentURL", title: "Content URL", indexingKey: \CSSearchableItemAttributeSet.contentURL)
		var contentURL: URL?
	#endif

	init(id: String, subjects: [SubjectEntity], sender: String? = nil, receivedAt: Date? = nil) {
		self.id = id
		self.subjects = subjects
		#if !os(watchOS)
			searchDescription = ""
			searchKeywords = []
			contentURL = nil
		#endif
		if let sender, let receivedAt {
			sharedInfo = SharedInfo(receivedAt: receivedAt, sender: sender)
		}
		#if !os(watchOS)
			let names = subjects.map(\.name)
			searchDescription = "\(subjects.count) subjects" + (names.isEmpty ? "" : ": \(names.prefix(8).joined(separator: ", "))")
			searchKeywords = [sender].compactMap(\.self) + names
			let rawReceivedID = id.hasPrefix("timetable.received.") ? String(id.dropFirst("timetable.received.".count)) : nil
			contentURL = if let rawReceivedID {
				URL(string: "timetable://received/\(rawReceivedID)")
			} else {
				URL(string: "timetable://owner")
			}
		#endif
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
