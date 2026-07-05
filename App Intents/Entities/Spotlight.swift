//
//   Spotlight.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import CoreSpotlight
import Defaults

actor SpotlightIndexer {
	static let shared = SpotlightIndexer()
	private let timetableIndex = CSSearchableIndex(name: "Timetables")
	private let subjectIndex = CSSearchableIndex(name: "Subjects")

	func rebuildFromDefaults() async {
		do {
			try await removeAll()
			var timetables = Defaults[.receivedTimetables]
				.filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }
				.toTimetableEntities()
			timetables.append(Defaults[.timetable].toTimetableEntity())
			try await timetableIndex.indexAppEntities(timetables)
			try await subjectIndex.indexAppEntities(timetables.flatMap(\.subjects))
		} catch {
			PrintError("Spotlight indexing failed", category: .spotlight, error: error)
		}
	}

	func removeAll() async throws {
		try await timetableIndex.deleteAllSearchableItems()
		try await subjectIndex.deleteAllSearchableItems()
	}
}

func indexEntities() async {
	await SpotlightIndexer.shared.rebuildFromDefaults()
}
