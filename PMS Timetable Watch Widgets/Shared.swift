//
//  Shared.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import Foundation
import WidgetKit

let periodTimes: [(start: (hour: Int, min: Int), end: (hour: Int, min: Int))] = [
	((8, 50), (9, 48)), // Period 1
	((9, 48), (10, 46)), // Period 2
	((11, 8), (12, 6)), // Period 3
	((12, 6), (13, 4)), // Period 4
	((13, 34), (14, 32)), // Period 5
	((14, 32), (15, 30)), // Period 6
]

struct Provider: TimelineProvider {
	func placeholder(in _: Context) -> TimetableEntry {
		TimetableEntry(date: Date(), classes: [], displayMode: .symbolsOnly)
	}

	func getSnapshot(in _: Context, completion: @escaping (TimetableEntry) -> Void) {
		let classes = Defaults[.timetable]
		let displayMode = Defaults[.displayMode]
		print("[Widget] getSnapshot: classes=\(classes.count), displayMode=\(displayMode.rawValue)")
		let entry = TimetableEntry(date: Date(), classes: classes, displayMode: displayMode)
		completion(entry)
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
		let classes = Defaults[.timetable]
		let displayMode = Defaults[.displayMode]
		let now = Date()
		var entries: [TimetableEntry] = []

		let calendar = Calendar.current
		let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)

		// 1. Initial entry for right now
		entries.append(TimetableEntry(date: now, classes: classes, displayMode: displayMode))

		// 2. Generate future entries for every period start and end time
		for period in periodTimes {
			var startComp = todayComponents
			startComp.hour = period.start.hour
			startComp.minute = period.start.min

			var endComp = todayComponents
			endComp.hour = period.end.hour
			endComp.minute = period.end.min

			if let startDate = calendar.date(from: startComp), startDate > now {
				entries.append(TimetableEntry(date: startDate, classes: classes, displayMode: displayMode))
			}

			if let endDate = calendar.date(from: endComp), endDate > now {
				entries.append(TimetableEntry(date: endDate, classes: classes, displayMode: displayMode))
			}
		}

		// Fix: Correct sorting syntax and variable names
		let sortedEntries = entries.sorted(by: { $0.date < $1.date })

		// 3. Define the refresh policy (e.g., refresh tomorrow morning)
		let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
		let nextDayRefresh = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow) ?? tomorrow

		// Fix: Explicitly type the Timeline to help the compiler infer EntryType
		let timeline = Timeline<TimetableEntry>(entries: sortedEntries, policy: .after(nextDayRefresh))
		completion(timeline)
	}
}

struct TimetableEntry: TimelineEntry {
	let date: Date
	let classes: [Class]
	let displayMode: DisplayMode
}
