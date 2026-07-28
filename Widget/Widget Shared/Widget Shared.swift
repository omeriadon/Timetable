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
		let schoolCalendar = Defaults[.schoolCalendar]
		return TimetableEntry(
			date: date,
			subjects: debugTimetable,
			ownerSchedule: scheduleItem(name: "You", subjects: debugTimetable, at: date, schoolCalendar: schoolCalendar),
			friendSchedules: [
				scheduleItem(name: "Alex", subjects: debugTimetable, at: date, schoolCalendar: schoolCalendar),
				scheduleItem(name: "Sam", subjects: debugTimetable, at: date, schoolCalendar: schoolCalendar),
			],
			isPlaceholder: true,
			relevance: nil
		)
	}

	func getSnapshot(in _: Context, completion: @escaping (TimetableEntry) -> Void) {
		let subjects = Defaults[.timetable]
		let friends = Defaults[.friends]
		let schoolCalendar = Defaults[.schoolCalendar]
		completion(
			TimetableEntry(
				date: .now,
				subjects: subjects,
				ownerSchedule: scheduleItem(name: "You", subjects: subjects, at: .now, schoolCalendar: schoolCalendar),
				friendSchedules: friendSchedules(for: friends, at: .now, schoolCalendar: schoolCalendar),
				isPlaceholder: false,
				relevance: nil
			)
		)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
		let subjects = Defaults[.timetable]
		let friends = Defaults[.friends]
		let schoolCalendar = Defaults[.schoolCalendar]

		let calendar = SchoolCalendarProjection.perthCalendar
		let now = TimetableClock.now

		guard let schoolDay = nextSchoolDay(from: now, calendar: calendar, schoolCalendar: schoolCalendar) else {
			completion(
				Timeline(
					entries: [
						makeEntry(date: now, subjects: subjects, friends: friends, calendar: calendar, schoolCalendar: schoolCalendar),
					],
					policy: .after(now.addingTimeInterval(60 * 60))
				)
			)
			return
		}

		var entries: [TimetableEntry] = [
			makeEntry(date: now, subjects: subjects, friends: friends, calendar: calendar, schoolCalendar: schoolCalendar),
		]

		guard
			let dayIndex = schoolCalendar.dayIndex(for: schoolDay, calendar: calendar),
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
			makeEntry(date: preSchool, subjects: subjects, friends: friends, calendar: calendar, schoolCalendar: schoolCalendar)
		)

		for period in SchoolStateEngine.activePeriods(for: dayIndex) {
			if let start = calendar.date(
				bySettingHour: period.start.hour,
				minute: period.start.minute,
				second: 0,
				of: schoolDay
			) {
				entries.append(
					makeEntry(date: start, subjects: subjects, friends: friends, calendar: calendar, schoolCalendar: schoolCalendar)
				)
			}

			if let end = calendar.date(
				bySettingHour: period.end.hour,
				minute: period.end.minute,
				second: 0,
				of: schoolDay
			) {
				entries.append(
					makeEntry(date: end, subjects: subjects, friends: friends, calendar: calendar, schoolCalendar: schoolCalendar)
				)
			}
		}

		entries.append(
			makeEntry(date: refreshAfterSchool, subjects: subjects, friends: friends, calendar: calendar, schoolCalendar: schoolCalendar)
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
	let nextScheduledSubject: ScheduledSubject?
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
	friends: [FriendSummary],
	calendar: Calendar,
	schoolCalendar: SchoolCalendarProjection
) -> TimetableEntry {
	TimetableEntry(
		date: date,
		subjects: subjects,
		ownerSchedule: scheduleItem(name: "You", subjects: subjects, at: date, schoolCalendar: schoolCalendar),
		friendSchedules: friendSchedules(for: friends, at: date, schoolCalendar: schoolCalendar),
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
	for friends: [FriendSummary],
	at date: Date,
	schoolCalendar: SchoolCalendarProjection
) -> [ScheduleItem] {
	friends.compactMap { friend in
		guard let timetable = friend.timetable else { return nil }
		return scheduleItem(name: friend.friend.displayName, subjects: timetable.subjects, at: date, schoolCalendar: schoolCalendar)
	}
}

private func scheduleItem(name: String, subjects: [Subject], at date: Date, schoolCalendar: SchoolCalendarProjection) -> ScheduleItem {
	let calendar = SchoolCalendarProjection.perthCalendar
	let adjustedDate = TimetableClock.adjusted(date)
	let state = SchoolStateEngine.calculate(at: adjustedDate, subjects: subjects, calendar: calendar, schoolCalendar: schoolCalendar)
	let nextScheduledSubject = SchoolStateEngine.nextScheduledSubject(
		after: adjustedDate,
		subjects: subjects,
		calendar: calendar,
		schoolCalendar: schoolCalendar
	)

	let backgroundColour: Color = switch state {
		case let .beforeSchool(next): next.subject.colour.swiftUIColor
		case let .lesson(lesson): lesson.subject.colour.swiftUIColor
		case .freePeriod: .blue
		case .recess, .lunch: .orange
		case .afterSchool, .weekend, .noTimetable: .black
	}

	return ScheduleItem(name: name, currentState: state, nextScheduledSubject: nextScheduledSubject, backgroundColour: backgroundColour)
}

// MARK: - nextSchoolDay

private func nextSchoolDay(
	from date: Date,
	calendar: Calendar,
	schoolCalendar: SchoolCalendarProjection
) -> Date? {
	var day = calendar.startOfDay(for: date)

	for _ in 0 ..< 370 {
		if schoolCalendar.isSchoolDay(day, calendar: calendar),
		   let dayIndex = schoolCalendar.dayIndex(for: day, calendar: calendar),
		   let schoolEnd = calendar.date(bySettingHour: SchoolStateEngine.schoolEnd(for: dayIndex).hour, minute: SchoolStateEngine.schoolEnd(for: dayIndex).minute, second: 0, of: day),
		   date < schoolEnd
		{
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
	let schoolCalendar = Defaults[.schoolCalendar]

	guard schoolCalendar.isSchoolDay(date, calendar: calendar) else {
		return TimelineEntryRelevance(score: 0, duration: 0)
	}

	guard
		let dayIndex = schoolCalendar.dayIndex(for: date, calendar: calendar),
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
