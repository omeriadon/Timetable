import AppIntents
import Foundation

struct ScheduledSubjectEntity: AppEntity, Identifiable {
	static var defaultQuery = ScheduledSubjectQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Scheduled Subject")

	let id: String
	let subject: SubjectEntity
	let person: PersonTimetableEntity
	let day: SchoolDayEntity
	let sessionNumber: Int
	let startDate: Date
	let endDate: Date
	let classroomName: String?
	let teacherName: String?

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: "\(subject.name) — \(person.displayName), \(day.name), \(startDate.formatted(date: .omitted, time: .shortened))")
	}
}

struct ScheduledSubjectQuery: EntityQuery {
	func entities(for identifiers: [String]) async throws -> [ScheduledSubjectEntity] {
		await MainActor.run {
			let wanted = Set(identifiers)
			return IntentTimetableResolver.all().flatMap { timetable in
				(0 ..< 5).flatMap { day in IntentScheduleHelpers.occurrences(for: timetable, day: day, date: TimetableClock.now).filter { wanted.contains($0.id) } }
			}
		}
	}
}

@MainActor
enum ScheduledSubjectEntityFactory {
	static func make(timetable: IntentTimetableResolver.ResolvedTimetable, subject: Subject, day: Int, session: Int, start: Date, end: Date) -> ScheduledSubjectEntity {
		let personID = timetable.isOwner ? PersonTimetableEntity.ownerID : timetable.receivedID ?? timetable.id
		let subjectID = "subject.\(timetable.isOwner ? "owner" : "received.\(timetable.receivedID ?? timetable.id)").\(subject.id)"
		return ScheduledSubjectEntity(id: "occurrence.\(timetable.id).\(subjectID).\(day).\(session)", subject: subject.toSubjectEntity(identifier: subjectID, timetable: timetable), person: timetable.person, day: SchoolDayEntity(id: day, name: TimetableLayout.fullDayLabels[day]), sessionNumber: session + 1, startDate: start, endDate: end, classroomName: subject.classroom.displayName, teacherName: subject.teacher.displayName)
	}
}
