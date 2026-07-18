import AppIntents
import Foundation

struct FreePeriodEntity: AppEntity, Identifiable {
	static var defaultQuery = FreePeriodQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Free Period")

	let id: String
	let person: PersonTimetableEntity
	let day: SchoolDayEntity
	let sessionNumber: Int
	let startDate: Date
	let endDate: Date

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: "Free Period", subtitle: "\(day.name), \(startDate.formatted(date: .omitted, time: .shortened))")
	}
}

struct FreePeriodQuery: EntityQuery {
	func entities(for identifiers: [String]) async throws -> [FreePeriodEntity] {
		await MainActor.run {
			let wanted = Set(identifiers)
			return IntentTimetableResolver.all().flatMap { timetable in
				(0 ..< 5).flatMap { day in IntentScheduleHelpers.freePeriods(for: timetable, day: day, date: TimetableClock.now).filter { wanted.contains($0.id) } }
			}
		}
	}
}

@MainActor
enum FreePeriodFactory {
	static func make(timetable: IntentTimetableResolver.ResolvedTimetable, day: Int, period: SchoolPeriod, start: Date, end: Date) -> FreePeriodEntity {
		FreePeriodEntity(id: "free.\(timetable.id).\(day).\(period.number)", person: timetable.person, day: SchoolDayEntity(id: day, name: TimetableLayout.fullDayLabels[day]), sessionNumber: period.number, startDate: start, endDate: end)
	}
}
