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
			let identifierSet = Set(identifiers)
			return IntentTimetableResolver.all().flatMap { timetable in
				timetable.subjects.compactMap { subject in
					let canonical = "subject.\(timetable.isOwner ? "owner" : "received.\(timetable.receivedID ?? timetable.id)").\(subject.id)"
					guard identifierSet.contains(canonical) || (timetable.isOwner && (identifierSet.contains(subject.id) || identifierSet.contains("subject.owner.\(subject.id)"))) else { return nil }
					return subject.toSubjectEntity(identifier: canonical, timetable: timetable)
				}
			}
		}
	}

	func entities(matching string: String) async -> [SubjectEntity] {
		await MainActor.run {
			let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !text.isEmpty else { return suggestedEntitiesSync() }
			return IntentTimetableResolver.all().flatMap { timetable in
				timetable.subjects.filter { $0.id.localizedCaseInsensitiveContains(text) || $0.teacher.displayName.localizedCaseInsensitiveContains(text) || $0.classroom.displayName.localizedCaseInsensitiveContains(text) || timetable.displayName.localizedCaseInsensitiveContains(text) }.map { subject in
					subject.toSubjectEntity(identifier: "subject.\(timetable.isOwner ? "owner" : "received.\(timetable.receivedID ?? timetable.id)").\(subject.id)", timetable: timetable)
				}
			}
		}
	}

	func suggestedEntities() async -> [SubjectEntity] {
		await MainActor.run {
			suggestedEntitiesSync()
		}
	}

	@MainActor
	private func suggestedEntitiesSync() -> [SubjectEntity] {
		IntentTimetableResolver.all().flatMap { timetable in
			timetable.subjects.map { subject in subject.toSubjectEntity(identifier: "subject.\(timetable.isOwner ? "owner" : "received.\(timetable.receivedID ?? timetable.id)").\(subject.id)", timetable: timetable) }
		}
	}
}
