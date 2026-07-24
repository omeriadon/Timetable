//
//   Widget Shared.swift
//   Widget
//
//   Created by Adon Omeri on 27/4/2026.
//

import Defaults
import Foundation
import SwiftUI
import WidgetKit

// MARK: - Provider

struct Provider: TimelineProvider {
	func placeholder(in _: Context) -> TimetableEntry {
		let date = placeholderSchoolDate()
		return TimetableEntry(
			date: date,
			subjects: debugTimetable,
			ownerSchedule: scheduleItem(name: "You", subjects: debugTimetable, at: date),
			friendSchedules: [
				scheduleItem(name: "Alex", subjects: debugTimetable, at: date),
				scheduleItem(name: "Sam", subjects: debugTimetable, at: date),
			],
			isPlaceholder: true,
			relevance: nil
		)
	}

	func getSnapshot(in _: Context, completion: @escaping (TimetableEntry) -> Void) {
		let subjects = Defaults[.timetable]
		let receivedTimetables = Defaults[.receivedTimetables]
		completion(
			TimetableEntry(
				date: .now,
				subjects: subjects,
				ownerSchedule: scheduleItem(name: "You", subjects: subjects, at: .now),
				friendSchedules: friendSchedules(for: receivedTimetables, at: .now),
				isPlaceholder: false,
				relevance: nil
			)
		)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
		let subjects = Defaults[.timetable]
		let receivedTimetables = Defaults[.receivedTimetables]

		let calendar = Calendar.current

		guard let schoolDay = nextSchoolDay(from: TimetableClock.now, calendar: calendar) else {
			completion(
				Timeline(
					entries: [
						makeEntry(date: .now, subjects: subjects, receivedTimetables: receivedTimetables, calendar: calendar),
					],
					policy: .after(Date().addingTimeInterval(60 * 60))
				)
			)
			return
		}

		var entries: [TimetableEntry] = []

		guard
			let dayIndex = schoolDayIndex(for: schoolDay, calendar: calendar),
			let schoolStart = calendar.date(
				bySettingHour: SchoolStateEngine.schoolStart.hour,
				minute: SchoolStateEngine.schoolStart.minute,
				second: 0,
				of: schoolDay
			),
			let schoolEnd = calendar.date(
				bySettingHour: SchoolStateEngine.schoolEnd(for: dayIndex).hour,
				minute: SchoolStateEngine.schoolEnd(for: dayIndex).minute,
				second: 0,
				of: schoolDay
			),
			let preSchool = calendar.date(
				byAdding: .hour,
				value: -1,
				to: schoolStart
			),
			let refreshAfterSchool = calendar.date(
				byAdding: .minute,
				value: 5,
				to: schoolEnd
			)
		else {
			return
		}

		entries.append(
			makeEntry(date: preSchool, subjects: subjects, receivedTimetables: receivedTimetables, calendar: calendar)
		)

		for period in SchoolStateEngine.activePeriods(for: dayIndex) {
			if let start = calendar.date(
				bySettingHour: period.start.hour,
				minute: period.start.minute,
				second: 0,
				of: schoolDay
			) {
				entries.append(
					makeEntry(date: start, subjects: subjects, receivedTimetables: receivedTimetables, calendar: calendar)
				)
			}

			if let end = calendar.date(
				bySettingHour: period.end.hour,
				minute: period.end.minute,
				second: 0,
				of: schoolDay
			) {
				entries.append(
					makeEntry(date: end, subjects: subjects, receivedTimetables: receivedTimetables, calendar: calendar)
				)
			}
		}

		entries.append(
			makeEntry(date: refreshAfterSchool, subjects: subjects, receivedTimetables: receivedTimetables, calendar: calendar)
		)

		completion(
			Timeline(
				entries: entries.sorted { $0.date < $1.date },
				policy: .after(refreshAfterSchool)
			)
		)
	}
}

// MARK: - Schedule Item

nonisolated struct ScheduleItem: Identifiable {
	var id: String {
		name
	}

	let name: String

	let currentState: SchoolState
	let backgroundColour: Color
}

// MARK: - TimetableEntry

struct TimetableEntry: TimelineEntry {
	let date: Date
	let subjects: [Subject]
	let ownerSchedule: ScheduleItem?
	let friendSchedules: [ScheduleItem]
	let isPlaceholder: Bool
	let relevance: TimelineEntryRelevance?
}

// MARK: - makeEntry

private func makeEntry(
	date: Date,
	subjects: [Subject],
	receivedTimetables: [ReceivedTimetable],
	calendar: Calendar
) -> TimetableEntry {
	TimetableEntry(
		date: date,
		subjects: subjects,
		ownerSchedule: scheduleItem(name: "You", subjects: subjects, at: date),
		friendSchedules: friendSchedules(for: receivedTimetables, at: date),
		isPlaceholder: false,
		relevance: relevance(for: date, calendar: calendar)
	)
}

private func placeholderSchoolDate(calendar: Calendar = .current) -> Date {
	let now = Date()
	var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
	components.weekday = 2
	components.hour = 10
	components.minute = 0
	return calendar.date(from: components) ?? now
}

private func friendSchedules(
	for receivedTimetables: [ReceivedTimetable],
	at date: Date
) -> [ScheduleItem] {
	receivedTimetables.map { timetable in
		scheduleItem(name: timetable.sender, subjects: timetable.subjects, at: date)
	}
}

private func scheduleItem(name: String, subjects: [Subject], at date: Date) -> ScheduleItem {
	let state = SchoolStateEngine.calculate(at: TimetableClock.adjusted(date), subjects: subjects)

	let backgroundColour: Color = switch state {
		case let .beforeSchool(next): next.subject.colour.swiftUIColor
		case let .lesson(lesson): lesson.subject.colour.swiftUIColor
		case .freePeriod: .blue
		case .recess, .lunch: .orange
		case .afterSchool, .weekend, .noTimetable: .black
	}

	return ScheduleItem(name: name, currentState: state, backgroundColour: backgroundColour)
}

// MARK: - nextSchoolDay

private func nextSchoolDay(
	from date: Date,
	calendar: Calendar
) -> Date? {
	var day = calendar.startOfDay(for: date)

	for _ in 0 ..< 7 {
		let weekday = calendar.component(.weekday, from: day)

		if (2 ... 6).contains(weekday) {
			return day
		}

		guard let next = calendar.date(
			byAdding: .day,
			value: 1,
			to: day
		) else {
			return nil
		}

		day = next
	}

	return nil
}

// MARK: - Relevance

private func relevance(
	for date: Date,
	calendar: Calendar
) -> TimelineEntryRelevance? {
	let weekday = calendar.component(.weekday, from: date)

	guard (2 ... 6).contains(weekday) else {
		return TimelineEntryRelevance(score: 0, duration: 0)
	}

	guard
		let dayIndex = schoolDayIndex(for: date, calendar: calendar),
		let schoolStart = calendar.date(
			bySettingHour: SchoolStateEngine.schoolStart.hour,
			minute: SchoolStateEngine.schoolStart.minute,
			second: 0,
			of: date
		),
		let schoolEnd = calendar.date(
			bySettingHour: SchoolStateEngine.schoolEnd(for: dayIndex).hour,
			minute: SchoolStateEngine.schoolEnd(for: dayIndex).minute,
			second: 0,
			of: date
		),
		let relevantStart = calendar.date(
			byAdding: .hour,
			value: -1,
			to: schoolStart
		)
	else {
		return nil
	}

	if date >= relevantStart, date <= schoolEnd {
		return TimelineEntryRelevance(
			score: 1.0,
			duration: schoolEnd.timeIntervalSince(date)
		)
	}

	return TimelineEntryRelevance(score: 0, duration: 0)
}

private func schoolDayIndex(for date: Date, calendar: Calendar) -> Int? {
	let weekday = calendar.component(.weekday, from: date)
	guard (2 ... 6).contains(weekday) else { return nil }
	return weekday - 2
}
