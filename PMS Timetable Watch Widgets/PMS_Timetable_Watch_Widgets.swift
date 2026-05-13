//
//  PMS_Timetable_Watch_Widgets.swift
//  PMS Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
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
		let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
		completion(timeline)
	}
}

struct TimetableEntry: TimelineEntry {
	let date: Date
	let classes: [Class]
	let displayMode: DisplayMode
}

struct PMS_Timetable_Watch_WidgetsEntryView: View {
	var entry: Provider.Entry

	var body: some View {
		WidgetView(classes: entry.classes, displayMode: entry.displayMode)
	}
}

struct PMS_Timetable_Watch_Widgets: Widget {
	let kind: String = "PMS_Timetable_Watch_Widgets"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			PMS_Timetable_Watch_WidgetsEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("PMS Timetable")
		.description("Your class schedule for the week.")
	}
}

#Preview(as: .accessoryRectangular) {
	PMS_Timetable_Watch_Widgets()
} timeline: {
	TimetableEntry(
		date: .now,
		classes: defaultTimetable,
		displayMode: .symbolsOnly
	)
}
