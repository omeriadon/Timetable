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
			.map { TimetableEntity(id: $0.id, ownerType: .shared, subjects: $0.subjects, sender: $0.sender, receivedAt: $0.receivedAt) }
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
			.map { TimetableEntity(id: $0.id, ownerType: .shared, subjects: $0.subjects, sender: $0.sender, receivedAt: $0.receivedAt) }
		}
	}

	func suggestedEntities() async throws -> [TimetableEntity] {
		return await MainActor.run {
			Defaults[.receivedTimetables]
				.map { TimetableEntity(id: $0.id, ownerType: .shared, subjects: $0.subjects, sender: $0.sender, receivedAt: $0.receivedAt) }
		}
	}
}
