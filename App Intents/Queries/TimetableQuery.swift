//
//   TimetableQuery.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct TimetableQuery: EntityStringQuery {
	func entities(for identifiers: [String]) async throws -> [TimetableEntity] {
		await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables].filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }

			var result = receivedTimetables.filter { t in
				identifiers.contains(t.id) || identifiers.contains("timetable.received.\(t.id)") ||
					identifiers.contains(t.sender) ||
					t.subjects.contains { identifiers.contains($0.id) }
			}.toTimetableEntities()
			if identifiers.contains("timetable.owner") { result.append(TimetableEntity(id: "timetable.owner", subjects: Defaults[.timetable].toSubjectEntities(prefix: "subject.owner"))) }
			return result
		}
	}

	func entities(matching string: String) async throws -> [TimetableEntity] {
		await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables].filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }

			return receivedTimetables.filter { t in
				t.sender.localizedCaseInsensitiveContains(string) ||
					t.subjects.contains { $0.id.localizedCaseInsensitiveContains(string)
					}
			}
			.toTimetableEntities()
		}
	}

	func suggestedEntities() async throws -> [TimetableEntity] {
		await MainActor.run {
			let received = Defaults[.receivedTimetables].filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }.toTimetableEntities()
			return [TimetableEntity(id: "timetable.owner", subjects: Defaults[.timetable].toSubjectEntities(prefix: "subject.owner"))] + received
		}
	}
}
