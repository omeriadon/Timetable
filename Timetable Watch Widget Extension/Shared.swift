//
//  Shared.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import Foundation
import WidgetKit

private let daysAhead = 5

struct Provider: TimelineProvider {
	func placeholder(in _: Context) -> TimetableEntry {
		TimetableEntry(date: .now, classes: [], displayMode: .symbolsOnly, relevance: nil)
	}

	func getSnapshot(in _: Context, completion: @escaping (TimetableEntry) -> Void) {
		let classes = Defaults[.timetable]
		let displayMode = Defaults[.displayMode]
		completion(
			TimetableEntry(
				date: .now,
				classes: classes,
				displayMode: displayMode,
				relevance: nil
			)
		)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
		let classes = Defaults[.timetable]
		let displayMode = Defaults[.displayMode]
		let now = Date()
		let calendar = Calendar.current

		var entries: [TimetableEntry] = [
			makeEntry(date: now, classes: classes, displayMode: displayMode, calendar: calendar),
		]

		for day in nextFiveWeekdays(from: now, calendar: calendar) {
			guard
				let schoolStart = calendar.date(bySettingHour: schoolStartHour, minute: schoolStartMinute, second: 0, of: day),
				let schoolEnd = calendar.date(bySettingHour: schoolEndHour, minute: schoolEndMinute, second: 0, of: day)
			else { continue }

			let isToday = calendar.isDate(day, inSameDayAs: now)
			var tick = isToday
				? nextTick(after: now, schoolStart: schoolStart, stepMinutes: tickMinutes, calendar: calendar)
				: schoolStart

			while tick <= schoolEnd {
				if tick > now {
					entries.append(
						makeEntry(date: tick, classes: classes, displayMode: displayMode, calendar: calendar)
					)
				}

				guard let next = calendar.date(byAdding: .minute, value: tickMinutes, to: tick) else { break }
				tick = next
			}
		}

		completion(Timeline(entries: entries, policy: .atEnd))
	}
}

struct TimetableEntry: TimelineEntry {
	let date: Date
	let classes: [Class]
	let displayMode: DisplayMode
	let relevance: TimelineEntryRelevance?
}

private func makeEntry(
	date: Date,
	classes: [Class],
	displayMode: DisplayMode,
	calendar: Calendar
) -> TimetableEntry {
	TimetableEntry(
		date: date,
		classes: classes,
		displayMode: displayMode,
		relevance: relevance(for: date, calendar: calendar)
	)
}

private func nextFiveWeekdays(from date: Date, calendar: Calendar) -> [Date] {
	var days: [Date] = []
	var current = calendar.startOfDay(for: date)

	while days.count < daysAhead {
		let weekday = calendar.component(.weekday, from: current)
		if (2 ... 6).contains(weekday) {
			days.append(current)
		}

		guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
		current = next
	}

	return days
}

private func nextTick(
	after now: Date,
	schoolStart: Date,
	stepMinutes: Int,
	calendar: Calendar
) -> Date {
	guard now > schoolStart else { return schoolStart }

	let minutesSinceStart = calendar.dateComponents([.minute], from: schoolStart, to: now).minute ?? 0
	let offset = ((minutesSinceStart / stepMinutes) + 1) * stepMinutes

	return calendar.date(byAdding: .minute, value: offset, to: schoolStart) ?? now
}

private func relevance(for date: Date, calendar: Calendar) -> TimelineEntryRelevance? {
	let weekday = calendar.component(.weekday, from: date)
	guard (2 ... 6).contains(weekday) else { return nil }

	let nowMins = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)

	for period in periodTimes {
		let startMins = period.start.hour * 60 + period.start.min
		let endMins = period.end.hour * 60 + period.end.min

		if nowMins >= startMins, nowMins < endMins,
		   let endDate = calendar.date(
		   	bySettingHour: period.end.hour,
		   	minute: period.end.min,
		   	second: 0,
		   	of: date
		   )
		{
			return TimelineEntryRelevance(score: 1.0, duration: endDate.timeIntervalSince(date))
		}
	}

	for i in 0 ..< (periodTimes.count - 1) {
		let breakStart = periodTimes[i].end
		let breakEnd = periodTimes[i + 1].start

		let startMins = breakStart.hour * 60 + breakStart.min
		let endMins = breakEnd.hour * 60 + breakEnd.min

		if nowMins >= startMins, nowMins < endMins,
		   let endDate = calendar.date(
		   	bySettingHour: breakEnd.hour,
		   	minute: breakEnd.min,
		   	second: 0,
		   	of: date
		   )
		{
			return TimelineEntryRelevance(score: 0.0, duration: endDate.timeIntervalSince(date))
		}
	}

	return nil
}
