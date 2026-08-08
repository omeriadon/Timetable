import AppIntents
import Defaults
import Foundation

@MainActor
enum IntentTimetableResolver {
	struct ResolvedTimetable: Identifiable {
		let id: String
		let displayName: String
		let subjects: [Subject]
		let isOwner: Bool

		var person: PersonTimetableEntity {
			PersonTimetableEntity(id: PersonTimetableEntity.ownerID, displayName: displayName)
		}
	}

	static func resolve(_ person: PersonTimetableEntity?) -> ResolvedTimetable? {
		resolve(personID: person?.id ?? PersonTimetableEntity.ownerID)
	}

	static func resolve(personID: String) -> ResolvedTimetable? {
		if personID == PersonTimetableEntity.ownerID || personID == "timetable.owner" {
			return ResolvedTimetable(id: "timetable.owner", displayName: "You", subjects: Defaults[.timetable], isOwner: true)
		}

		return nil
	}

	static func all() -> [ResolvedTimetable] {
		resolve(personID: PersonTimetableEntity.ownerID).map { [$0] } ?? []
	}

	static func timetableURL(for _: ResolvedTimetable) -> URL {
		let route = AppRoute.timetable(.root)
		guard let url = route.url else {
			preconditionFailure("Unable to encode timetable route.")
		}
		return url
	}

	static func subjectURL(for _: ResolvedTimetable, subjectID: String, day: Int? = nil, session: Int? = nil) -> URL {
		let slot: Slot? = if let day,
		                     let session,
		                     (0 ..< 5).contains(day),
		                     TimetableLayout.period(forSession: session) != nil
		{
			Slot(day, session)
		} else {
			nil
		}
		let route = AppRoute.timetable(
			.subject(
				timetableID: nil,
				subjectID: subjectID,
				slot: slot
			)
		)
		guard let url = route.url else {
			preconditionFailure("Unable to encode subject route.")
		}
		return url
	}
}
