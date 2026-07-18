import Foundation

@MainActor
enum IntentScheduleHelpers {
	static func occurrences(for timetable: IntentTimetableResolver.ResolvedTimetable, day: Int, date: Date) -> [ScheduledSubjectEntity] {
		guard (0 ..< 5).contains(day) else { return [] }
		let lookup = TimetableLayout.subjectLookup(for: timetable.subjects)
		return SchoolStateEngine.periods.compactMap { period in
			guard TimetableLayout.canUse(period: period.number, on: day), let session = TimetableLayout.session(forPeriod: period.number), let subject = lookup[Slot(day, session)], let start = clockDate(period.start, on: date), let end = clockDate(period.end, on: date) else { return nil }
			return ScheduledSubjectEntityFactory.make(timetable: timetable, subject: subject, day: day, session: session, start: start, end: end)
		}
	}

	static func freePeriods(for timetable: IntentTimetableResolver.ResolvedTimetable, day: Int, date: Date) -> [FreePeriodEntity] {
		guard !timetable.subjects.isEmpty else { return [] }
		let lookup = TimetableLayout.subjectLookup(for: timetable.subjects)
		return SchoolStateEngine.periods.compactMap { period in
			guard TimetableLayout.canUse(period: period.number, on: day), let session = TimetableLayout.session(forPeriod: period.number), lookup[Slot(day, session)] == nil, let start = clockDate(period.start, on: date), let end = clockDate(period.end, on: date) else { return nil }
			return FreePeriodFactory.make(timetable: timetable, day: day, period: period, start: start, end: end)
		}
	}

	static func nextOccurrence(of subjectID: String, timetable: IntentTimetableResolver.ResolvedTimetable, after now: Date) -> ScheduledSubjectEntity? {
		let calendar = Calendar.current
		for offset in 0 ... 7 {
			guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
			let weekday = calendar.component(.weekday, from: date)
			guard (2 ... 6).contains(weekday) else { continue }
			let day = weekday - 2
			for occurrence in occurrences(for: timetable, day: day, date: date) where occurrence.subject.name == subjectID {
				if occurrence.startDate > now {
					return occurrence
				}
			}
		}
		return nil
	}

	static func clockDate(_ time: TimeOfDay, on date: Date) -> Date? {
		Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: date)
	}
}
