//
//  SubjectQuery.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct SubjectQuery: EntityStringQuery {
	func entities(for identifiers: [String]) async -> [Subject] {
		return await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables]
			let identifierSet = Set(identifiers)

			// Extract the flat array explicitly using the wrapped property values
			let allSubjects = receivedTimetables.flatMap { timetable -> [Subject] in
				return timetable.subjects
			}

			return allSubjects.filter { identifierSet.contains($0.id) }
		}
	}

	func entities(matching string: String) async -> [Subject] {
		return await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables]

			let allSubjects = receivedTimetables.flatMap { timetable -> [Subject] in
				return timetable.subjects
			}

			return allSubjects.filter { $0.id.localizedCaseInsensitiveContains(string) }
		}
	}

	func suggestedEntities() async -> [Subject] {
		return await MainActor.run {
			let receivedTimetables = Defaults[.receivedTimetables]

			return receivedTimetables.flatMap { timetable -> [Subject] in
				return timetable.subjects
			}
		}
	}
}
