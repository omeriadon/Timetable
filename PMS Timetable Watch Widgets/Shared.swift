//
//  Shared.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import Foundation
import WidgetKit

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

	func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		let classes = Defaults[.timetable]
		let displayMode = Defaults[.displayMode]
		print("[Widget] getTimeline: classes=\(classes.count), displayMode=\(displayMode.rawValue)")
		let entry = TimetableEntry(date: Date(), classes: classes, displayMode: displayMode)

		// Refresh every 30 seconds to keep time remaining accurate
		let nextUpdate = Date().addingTimeInterval(30)
		let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
		completion(timeline)
	}
}

struct TimetableEntry: TimelineEntry {
	let date: Date
	let classes: [Class]
	let displayMode: DisplayMode
}
