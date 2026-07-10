//
//   SubjectQuery.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct SubjectQuery: EntityStringQuery {
	func entities(for identifiers: [String]) async -> [SubjectEntity] {
		await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables].filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }
			let identifierSet = Set(identifiers)

			var result = Defaults[.timetable].filter { identifierSet.contains("subject.owner.\($0.id)") || identifierSet.contains($0.id) }.toSubjectEntities(prefix: "subject.owner")
			result += receivedTimetables.flatMap { timetable in timetable.subjects.filter { identifierSet.contains("subject.received.\(timetable.id).\($0.id)") }.toSubjectEntities(prefix: "subject.received.\(timetable.id)") }
			return result
		}
	}

	func entities(matching string: String) async -> [SubjectEntity] {
		await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables].filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }

			return Defaults[.timetable].filter { $0.id.localizedCaseInsensitiveContains(string) }.toSubjectEntities(prefix: "subject.owner") + receivedTimetables.flatMap { timetable in
				timetable.subjects.filter { $0.id.localizedCaseInsensitiveContains(string) }.toSubjectEntities(prefix: "subject.received.\(timetable.id)")
			}
		}
	}

	func suggestedEntities() async -> [SubjectEntity] {
		await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables].filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }

			return Defaults[.timetable].toSubjectEntities(prefix: "subject.owner") + receivedTimetables
				.flatMap { timetable -> [SubjectEntity] in
					return timetable.subjects.toSubjectEntities(prefix: "subject.received.\(timetable.id)")
				}
		}
	}
}
