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
			IntentTimetableResolver.all().compactMap { timetable in
				let aliases = timetable.isOwner ? ["owner", "timetable.owner"] : [timetable.id, timetable.receivedID ?? ""]
				guard identifiers.contains(where: { aliases.contains($0) }) else { return nil }
				return TimetableEntity(id: timetable.id, subjects: timetable.subjects.toSubjectEntities(prefix: timetable.isOwner ? "subject.owner" : "subject.received.\(timetable.receivedID ?? timetable.id)"), sender: timetable.isOwner ? nil : timetable.displayName, receivedAt: timetable.isOwner ? nil : Date())
			}
		}
	}

	func entities(matching string: String) async throws -> [TimetableEntity] {
		await MainActor.run {
			let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !text.isEmpty else { return suggestedSync() }
			return IntentTimetableResolver.all().filter { timetable in timetable.displayName.localizedCaseInsensitiveContains(text) || timetable.subjects.contains { $0.id.localizedCaseInsensitiveContains(text) || $0.teacher.displayName.localizedCaseInsensitiveContains(text) || $0.classroom.displayName.localizedCaseInsensitiveContains(text) } }.map { timetable in
				TimetableEntity(id: timetable.id, subjects: timetable.subjects.toSubjectEntities(prefix: timetable.isOwner ? "subject.owner" : "subject.received.\(timetable.receivedID ?? timetable.id)"), sender: timetable.isOwner ? nil : timetable.displayName, receivedAt: timetable.isOwner ? nil : Date())
			}
		}
	}

	func suggestedEntities() async throws -> [TimetableEntity] {
		await MainActor.run {
			suggestedSync()
		}
	}

	@MainActor private func suggestedSync() -> [TimetableEntity] {
		IntentTimetableResolver.all().map { timetable in TimetableEntity(id: timetable.id, subjects: timetable.subjects.toSubjectEntities(prefix: timetable.isOwner ? "subject.owner" : "subject.received.\(timetable.receivedID ?? timetable.id)"), sender: timetable.isOwner ? nil : timetable.displayName, receivedAt: timetable.isOwner ? nil : Date()) }
	}
}
