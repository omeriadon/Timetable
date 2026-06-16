//
//  Shared.swift
//  Widget Extension
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import Foundation
import WidgetKit

//MARK: - Provider

struct Provider: TimelineProvider {
	func placeholder(in _: Context) -> TimetableEntry {
		TimetableEntry(date: .now, classes: [], relevance: nil)
	}

	func getSnapshot(in _: Context, completion: @escaping (TimetableEntry) -> Void) {
		let classes = Defaults[.timetable]
		completion(
			TimetableEntry(
				date: .now,
				classes: classes,
				relevance: nil
			)
		)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
		let classes = Defaults[.timetable]
		let calendar = Calendar.current

		guard let schoolDay = nextSchoolDay(from: .now, calendar: calendar) else {
			completion(
				Timeline(
					entries: [
						makeEntry(date: .now, classes: classes, calendar: calendar),
					],
					policy: .after(Date().addingTimeInterval(60 * 60))
				)
			)
			return
		}

		var entries: [TimetableEntry] = []

		guard
			let schoolStart = calendar.date(
				bySettingHour: schoolStartHour,
				minute: schoolStartMinute,
				second: 0,
				of: schoolDay
			),
			let schoolEnd = calendar.date(
				bySettingHour: schoolEndHour,
				minute: schoolEndMinute,
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
			makeEntry(date: preSchool, classes: classes, calendar: calendar)
		)

		for period in periodTimes {
			if let start = calendar.date(
				bySettingHour: period.start.hour,
				minute: period.start.min,
				second: 0,
				of: schoolDay
			) {
				entries.append(
					makeEntry(date: start, classes: classes, calendar: calendar)
				)
			}

			if let end = calendar.date(
				bySettingHour: period.end.hour,
				minute: period.end.min,
				second: 0,
				of: schoolDay
			) {
				entries.append(
					makeEntry(date: end, classes: classes, calendar: calendar)
				)
			}
		}

		entries.append(
			makeEntry(date: refreshAfterSchool, classes: classes, calendar: calendar)
		)

		completion(
			Timeline(
				entries: entries.sorted { $0.date < $1.date },
				policy: .after(refreshAfterSchool)
			)
		)
	}
}

// MARK: - TimetableEntry

struct TimetableEntry: TimelineEntry {
	let date: Date
	let classes: [Class]
	let relevance: TimelineEntryRelevance?
}

// MARK: - makeEntry

private func makeEntry(
	date: Date,
	classes: [Class],
	calendar: Calendar
) -> TimetableEntry {
	TimetableEntry(
		date: date,
		classes: classes,
		relevance: relevance(for: date, calendar: calendar)
	)
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
		let schoolStart = calendar.date(
			bySettingHour: schoolStartHour,
			minute: schoolStartMinute,
			second: 0,
			of: date
		),
		let schoolEnd = calendar.date(
			bySettingHour: schoolEndHour,
			minute: schoolEndMinute,
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
