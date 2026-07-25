//
//  School State Logic.swift
//  Shared
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import Foundation

nonisolated struct TimeOfDay: Codable, Hashable {
	let hour: Int
	let minute: Int

	init(_ hour: Int, _ minute: Int) {
		self.hour = hour
		self.minute = minute
	}

	var minutesSinceMidnight: Int {
		hour * 60 + minute
	}
}

nonisolated struct SchoolCalendarDate: Codable, Hashable, Sendable {
	let year: Int
	let month: Int
	let day: Int

	var components: DateComponents {
		DateComponents(year: year, month: month, day: day)
	}
}

nonisolated struct SchoolCalendarDateRange: Codable, Hashable, Sendable {
	let label: String
	let start: SchoolCalendarDate
	let end: SchoolCalendarDate
}

nonisolated struct SchoolCalendarNamedDate: Codable, Hashable, Sendable {
	let date: SchoolCalendarDate
	let label: String
}

/// The server-owned definition of dates on which the timetable is active.
nonisolated struct SchoolCalendarProjection: Defaults.Serializable, Codable, Hashable, Sendable {
	let termRanges: [SchoolCalendarDateRange]
	let skippedDates: [SchoolCalendarNamedDate]

	static let empty = SchoolCalendarProjection(termRanges: [], skippedDates: [])

	static var perthCalendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(identifier: "Australia/Perth") ?? .current
		return calendar
	}

	func isSchoolDay(_ date: Date, calendar: Calendar = Self.perthCalendar) -> Bool {
		let day = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
		guard let weekday = day.weekday,
		      (2 ... 6).contains(weekday),
		      let schoolDate = calendar.date(from: day)
		else {
			return false
		}

		let dateKey = SchoolCalendarDate(year: day.year ?? 0, month: day.month ?? 0, day: day.day ?? 0)
		guard !skippedDates.contains(where: { $0.date == dateKey }) else { return false }

		return termRanges.contains { range in
			guard let start = calendar.date(from: range.start.components),
			      let end = calendar.date(from: range.end.components)
			else {
				return false
			}
			return schoolDate >= start && schoolDate <= end
		}
	}

	func dayIndex(for date: Date, calendar: Calendar = Self.perthCalendar) -> Int? {
		let weekday = calendar.component(.weekday, from: date)
		guard (2 ... 6).contains(weekday) else {
			return nil
		}
		return weekday - 2
	}
}

nonisolated struct SchoolPeriod: Codable, Hashable {
	let number: Int
	let start: TimeOfDay
	let end: TimeOfDay

	init(_ number: Int, _ start: TimeOfDay, _ end: TimeOfDay) {
		self.number = number
		self.start = start
		self.end = end
	}
}

nonisolated struct SchoolInterval: Hashable {
	let start: Date
	let end: Date

	var range: ClosedRange<Date> {
		start ... end
	}
}

nonisolated struct ScheduledSubject: Hashable {
	let subject: Subject
	let period: SchoolPeriod
	let interval: SchoolInterval
}

nonisolated struct CurrentLesson: Hashable {
	let subject: Subject
	let period: SchoolPeriod
	let interval: SchoolInterval
	let next: SchoolStateDestination
}

nonisolated struct CurrentFreePeriod: Hashable {
	let period: SchoolPeriod
	let interval: SchoolInterval
	let next: SchoolStateDestination
}

nonisolated struct BreakState: Hashable {
	let interval: SchoolInterval
	let next: SchoolStateDestination
}

nonisolated enum BreakType: String, Codable, Hashable {
	case recess
	case lunch

	var description: String {
		switch self {
			case .recess: "Recess"
			case .lunch: "Lunch"
		}
	}

	var symbol: String {
		switch self {
			case .recess: "cup.and.saucer.fill"
			case .lunch: "takeoutbag.and.cup.and.straw.fill"
		}
	}
}

nonisolated enum SchoolStateDestination: Hashable {
	case subject(Subject)
	case freePeriod
	case recess
	case lunch
	case endOfDay

	var title: String {
		switch self {
			case let .subject(subject): subject.id
			case .freePeriod: "Free Period"
			case .recess: "Recess"
			case .lunch: "Lunch"
			case .endOfDay: "Last Period"
		}
	}
}

nonisolated enum SchoolState: Hashable {
	case beforeSchool(next: ScheduledSubject)
	case lesson(CurrentLesson)
	case freePeriod(CurrentFreePeriod)
	case recess(BreakState)
	case lunch(BreakState)
	case afterSchool
	case weekend
	case noTimetable

	var interval: SchoolInterval? {
		switch self {
			case let .beforeSchool(next): next.interval
			case let .lesson(lesson): lesson.interval
			case let .freePeriod(period): period.interval
			case let .recess(state), let .lunch(state): state.interval
			case .afterSchool, .weekend, .noTimetable: nil
		}
	}

	var nextDestination: SchoolStateDestination? {
		switch self {
			case let .beforeSchool(next): .subject(next.subject)
			case let .lesson(lesson): lesson.next
			case let .freePeriod(period): period.next
			case let .recess(state), let .lunch(state): state.next
			case .afterSchool, .weekend, .noTimetable: nil
		}
	}
}

nonisolated enum TimetableClock {
	static var now: Date {
		Date().addingTimeInterval(debugOffset)
	}

	static func adjusted(_ date: Date) -> Date {
		date.addingTimeInterval(debugOffset)
	}
}

nonisolated enum SchoolStateEngine {
	static let periods: [SchoolPeriod] = [
		SchoolPeriod(1, TimeOfDay(8, 50), TimeOfDay(9, 48)),
		SchoolPeriod(2, TimeOfDay(9, 48), TimeOfDay(10, 46)),
		SchoolPeriod(3, TimeOfDay(11, 8), TimeOfDay(12, 6)),
		SchoolPeriod(4, TimeOfDay(12, 6), TimeOfDay(13, 4)),
		SchoolPeriod(5, TimeOfDay(13, 34), TimeOfDay(14, 32)),
		SchoolPeriod(6, TimeOfDay(14, 32), TimeOfDay(15, 30)),
	]

	static let schoolStart = TimeOfDay(8, 50)
	static let schoolEnd = TimeOfDay(15, 30)

	static func activePeriods(for dayIndex: Int) -> [SchoolPeriod] {
		periods.filter { TimetableLayout.canUse(period: $0.number, on: dayIndex) }
	}

	static func schoolEnd(for dayIndex: Int) -> TimeOfDay {
		activePeriods(for: dayIndex).last?.end ?? schoolEnd
	}

	@MainActor
	static func currentOwnerState() -> SchoolState {
		calculate(at: TimetableClock.now, subjects: Defaults[.timetable], schoolCalendar: Defaults[.schoolCalendar])
	}

	@MainActor
	static func currentReceivedStates() -> [ReceivedSchoolState] {
		Defaults[.receivedTimetables]
			.filter { !$0.isDeleted }
			.map {
				ReceivedSchoolState(
					id: $0.id,
					displayName: $0.sender,
					state: calculate(at: TimetableClock.now, subjects: $0.subjects, schoolCalendar: Defaults[.schoolCalendar])
				)
			}
	}

	@MainActor
	static func state(forReceivedTimetableID id: String) -> SchoolState {
		guard let timetable = Defaults[.receivedTimetables].first(where: { $0.id == id }),
		      !timetable.isDeleted
		else {
			return .noTimetable
		}

		return calculate(at: TimetableClock.now, subjects: timetable.subjects, schoolCalendar: Defaults[.schoolCalendar])
	}

	@MainActor
	static func timelineTransitions(forReceivedTimetableID id: String) -> [Date] {
		guard let timetable = Defaults[.receivedTimetables].first(where: { $0.id == id }) else {
			return []
		}

		return timelineTransitions(on: TimetableClock.now, subjects: timetable.subjects, schoolCalendar: Defaults[.schoolCalendar])
	}

	static func calculate(
		at date: Date,
		subjects: [Subject],
		calendar: Calendar = SchoolCalendarProjection.perthCalendar,
		schoolCalendar: SchoolCalendarProjection = .empty
	) -> SchoolState {
		guard !subjects.isEmpty else { return .noTimetable }
		guard schoolCalendar.isSchoolDay(date, calendar: calendar),
		      let dayIndex = schoolCalendar.dayIndex(for: date, calendar: calendar)
		else { return .weekend }

		let lookup = TimetableLayout.subjectLookup(for: subjects)
		let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
		let dayEnd = schoolEnd(for: dayIndex)

		guard minute < dayEnd.minutesSinceMidnight else { return .afterSchool }

		if minute < schoolStart.minutesSinceMidnight {
			guard let first = periods.first,
			      let subject = subject(for: first, dayIndex: dayIndex, lookup: lookup),
			      let interval = interval(for: first, on: date, calendar: calendar)
			else {
				return .noTimetable
			}

			return .beforeSchool(next: ScheduledSubject(subject: subject, period: first, interval: interval))
		}

		for (index, period) in periods.enumerated() {
			guard TimetableLayout.canUse(period: period.number, on: dayIndex) else { continue }
			guard let periodInterval = interval(for: period, on: date, calendar: calendar) else { continue }

			if periodInterval.start <= date, date < periodInterval.end {
				let next = destination(afterPeriodAt: index, dayIndex: dayIndex, lookup: lookup)
				if let subject = subject(for: period, dayIndex: dayIndex, lookup: lookup) {
					return .lesson(CurrentLesson(subject: subject, period: period, interval: periodInterval, next: next))
				}

				return .freePeriod(CurrentFreePeriod(period: period, interval: periodInterval, next: next))
			}

			guard index < periods.count - 1,
			      let nextInterval = interval(for: periods[index + 1], on: date, calendar: calendar),
			      periodInterval.end <= date,
			      date < nextInterval.start
			else {
				continue
			}

			let state = BreakState(
				interval: SchoolInterval(start: periodInterval.end, end: nextInterval.start),
				next: destination(forPeriodAt: index + 1, dayIndex: dayIndex, lookup: lookup)
			)
			return index == 1 ? .recess(state) : .lunch(state)
		}

		return .afterSchool
	}

	static func timelineTransitions(
		on date: Date,
		subjects: [Subject],
		calendar: Calendar = SchoolCalendarProjection.perthCalendar,
		schoolCalendar: SchoolCalendarProjection = .empty
	) -> [Date] {
		guard !subjects.isEmpty,
		      schoolCalendar.isSchoolDay(date, calendar: calendar),
		      let dayIndex = schoolCalendar.dayIndex(for: date, calendar: calendar)
		else { return [] }

		return activePeriods(for: dayIndex).flatMap { period -> [Date] in
			guard let interval = interval(for: period, on: date, calendar: calendar) else { return [] }
			return [interval.start, interval.end]
		}.sorted()
	}

	static func nextBreak(
		after date: Date,
		subjects: [Subject],
		calendar: Calendar = SchoolCalendarProjection.perthCalendar,
		schoolCalendar: SchoolCalendarProjection = .empty
	) -> (type: BreakType, interval: SchoolInterval)? {
		guard !subjects.isEmpty,
		      schoolCalendar.isSchoolDay(date, calendar: calendar),
		      schoolCalendar.dayIndex(for: date, calendar: calendar) != nil
		else { return nil }

		let breaks: [(BreakType, Int, Int)] = [(.recess, 1, 2), (.lunch, 3, 4)]
		for (type, previousIndex, nextIndex) in breaks {
			guard let previous = interval(for: periods[previousIndex], on: date, calendar: calendar),
			      let next = interval(for: periods[nextIndex], on: date, calendar: calendar)
			else {
				continue
			}

			let interval = SchoolInterval(start: previous.end, end: next.start)
			if date < interval.end {
				return (type, interval)
			}
		}

		return nil
	}

	static func nextSubject(
		after date: Date,
		subjects: [Subject],
		calendar: Calendar = SchoolCalendarProjection.perthCalendar,
		schoolCalendar: SchoolCalendarProjection = .empty
	) -> ScheduledSubject? {
		guard schoolCalendar.isSchoolDay(date, calendar: calendar),
		      let dayIndex = schoolCalendar.dayIndex(for: date, calendar: calendar),
		      !subjects.isEmpty
		else { return nil }
		let lookup = TimetableLayout.subjectLookup(for: subjects)

		for period in periods {
			guard let periodInterval = interval(for: period, on: date, calendar: calendar),
			      date < periodInterval.end,
			      let subject = subject(for: period, dayIndex: dayIndex, lookup: lookup)
			else {
				continue
			}

			if date < periodInterval.start {
				return ScheduledSubject(subject: subject, period: period, interval: periodInterval)
			}
		}

		return nil
	}

	static func nextScheduledSubject(
		after date: Date,
		subjects: [Subject],
		calendar: Calendar = SchoolCalendarProjection.perthCalendar,
		schoolCalendar: SchoolCalendarProjection = .empty
	) -> ScheduledSubject? {
		guard !subjects.isEmpty else { return nil }
		if let next = nextSubject(after: date, subjects: subjects, calendar: calendar, schoolCalendar: schoolCalendar) {
			return next
		}

		var candidate = calendar.startOfDay(for: date)
		for _ in 0 ..< 370 {
			guard let followingDay = calendar.date(byAdding: .day, value: 1, to: candidate) else { return nil }
			candidate = followingDay
			guard schoolCalendar.isSchoolDay(candidate, calendar: calendar) else { continue }
			if let next = nextSubject(after: candidate, subjects: subjects, calendar: calendar, schoolCalendar: schoolCalendar) {
				return next
			}
		}
		return nil
	}

	static func subjects(onDayIndex dayIndex: Int, from subjects: [Subject]) -> [Subject] {
		guard (0 ..< 5).contains(dayIndex) else { return [] }
		let lookup = TimetableLayout.subjectLookup(for: subjects)
		return periods.compactMap { subject(for: $0, dayIndex: dayIndex, lookup: lookup) }
	}

	private static func interval(
		for period: SchoolPeriod,
		on date: Date,
		calendar: Calendar
	) -> SchoolInterval? {
		guard let start = calendar.date(
			bySettingHour: period.start.hour,
			minute: period.start.minute,
			second: 0,
			of: date
		), let end = calendar.date(
			bySettingHour: period.end.hour,
			minute: period.end.minute,
			second: 0,
			of: date
		) else {
			return nil
		}

		return SchoolInterval(start: start, end: end)
	}

	private static func subject(
		for period: SchoolPeriod,
		dayIndex: Int,
		lookup: [Slot: Subject]
	) -> Subject? {
		guard TimetableLayout.canUse(period: period.number, on: dayIndex),
		      let session = TimetableLayout.session(forPeriod: period.number)
		else {
			return nil
		}

		return lookup[Slot(dayIndex, session)]
	}

	private static func destination(
		forPeriodAt index: Int,
		dayIndex: Int,
		lookup: [Slot: Subject]
	) -> SchoolStateDestination {
		guard periods.indices.contains(index) else { return .endOfDay }
		guard TimetableLayout.canUse(period: periods[index].number, on: dayIndex) else { return .endOfDay }
		if let subject = subject(for: periods[index], dayIndex: dayIndex, lookup: lookup) {
			return .subject(subject)
		}
		return .freePeriod
	}

	private static func destination(
		afterPeriodAt index: Int,
		dayIndex: Int,
		lookup: [Slot: Subject]
	) -> SchoolStateDestination {
		guard index < periods.count - 1 else { return .endOfDay }
		let current = periods[index]
		let next = periods[index + 1]
		let gap = next.start.minutesSinceMidnight - current.end.minutesSinceMidnight
		if gap > 0 {
			return index == 1 ? .recess : .lunch
		}
		return destination(forPeriodAt: index + 1, dayIndex: dayIndex, lookup: lookup)
	}
}

nonisolated struct ReceivedSchoolState: Identifiable, Hashable {
	let id: String
	let displayName: String
	let state: SchoolState
}
