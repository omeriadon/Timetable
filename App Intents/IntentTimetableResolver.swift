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
		let receivedID: String?

		var person: PersonTimetableEntity {
			PersonTimetableEntity(id: isOwner ? PersonTimetableEntity.ownerID : receivedID ?? id, displayName: displayName)
		}
	}

	static func resolve(_ person: PersonTimetableEntity?) -> ResolvedTimetable? {
		resolve(personID: person?.id ?? PersonTimetableEntity.ownerID)
	}

	static func resolve(personID: String) -> ResolvedTimetable? {
		if personID == PersonTimetableEntity.ownerID || personID == "timetable.owner" {
			return ResolvedTimetable(id: "timetable.owner", displayName: "You", subjects: Defaults[.timetable], isOwner: true, receivedID: nil)
		}

		let rawID = personID.hasPrefix("timetable.received.") ? String(personID.dropFirst("timetable.received.".count)) : personID
		guard let received = Defaults[.receivedTimetables].first(where: { $0.id == rawID && !$0.isDeleted }) else { return nil }
		return ResolvedTimetable(id: "timetable.received.\(received.id)", displayName: received.sender, subjects: received.subjects, isOwner: false, receivedID: received.id)
	}

	static func all() -> [ResolvedTimetable] {
		let owner = resolve(personID: PersonTimetableEntity.ownerID).map { [$0] } ?? []
		let received = Defaults[.receivedTimetables]
			.filter { !$0.isDeleted }
			.sorted { lhs, rhs in
				let name = lhs.sender.localizedCaseInsensitiveCompare(rhs.sender)
				return name == .orderedSame ? lhs.id < rhs.id : name == .orderedAscending
			}
			.compactMap { resolve(personID: $0.id) }
		return owner + received
	}

	static func timetableURL(for timetable: ResolvedTimetable) -> URL {
		let route: AppRoute = if let receivedID = timetable.receivedID {
			.timetable(.received(id: receivedID))
		} else {
			.timetable(.root)
		}
		guard let url = route.url else {
			preconditionFailure("Unable to encode timetable route.")
		}
		return url
	}

	static func subjectURL(for timetable: ResolvedTimetable, subjectID: String, day: Int? = nil, session: Int? = nil) -> URL {
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
				timetableID: timetable.receivedID,
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
