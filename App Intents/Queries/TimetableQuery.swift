//
//  TimetableQuery.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct TimetableQuery: EntityStringQuery {
	func entities(for identifiers: [String]) async throws -> [TimetableEntity] {
		return await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables]

			return receivedTimetables.filter { t in
				identifiers.contains(t.id) ||
					identifiers.contains(t.sender) ||
					t.subjects.contains { identifiers.contains($0.id) }
			}
			.toTimetableEntities()
		}
	}

	func entities(matching string: String) async throws -> [TimetableEntity] {
		return await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables]

			return receivedTimetables.filter { t in
				t.sender.localizedCaseInsensitiveContains(string) ||
					t.subjects.contains { $0.id.localizedCaseInsensitiveContains(string)
					}
			}
			.toTimetableEntities()
		}
	}

	func suggestedEntities() async throws -> [TimetableEntity] {
		return await MainActor.run {
			Defaults[.receivedTimetables]
				.toTimetableEntities()
		}
	}
}
