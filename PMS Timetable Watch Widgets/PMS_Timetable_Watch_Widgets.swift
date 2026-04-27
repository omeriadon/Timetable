//
//  PMS_Timetable_Watch_Widgets.swift
//  PMS Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
	private let appGroupID = "group.com.omeriadon.pms-timetable"

	private var sharedDefaults: UserDefaults {
		UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
	}

	func placeholder(in context: Context) -> TimetableEntry {
		TimetableEntry(date: Date(), classes: [], displayMode: .symbolsOnly)
	}

	func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> ()) {
		let classes = loadClassesFromUserDefaults()
		let displayMode = loadDisplayModeFromUserDefaults()
		let entry = TimetableEntry(date: Date(), classes: classes, displayMode: displayMode)
		completion(entry)
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		let classes = loadClassesFromUserDefaults()
		let displayMode = loadDisplayModeFromUserDefaults()
		let entry = TimetableEntry(date: Date(), classes: classes, displayMode: displayMode)
		let timeline = Timeline(entries: [entry], policy: .never)
		completion(timeline)
	}

	private func loadClassesFromUserDefaults() -> [Class] {
		guard let data = sharedDefaults.data(forKey: "watchTimetableCache") else {
			print("[Widget] No cached timetable found in shared storage")
			return []
		}

		do {
			let classes = try JSONDecoder().decode([Class].self, from: data)
			print("[Widget] Loaded \(classes.count) classes from shared storage")
			return classes
		} catch {
			print("[Widget] Failed to decode classes: \(error)")
			return []
		}
	}

	private func loadDisplayModeFromUserDefaults() -> DisplayMode {
		guard let data = sharedDefaults.data(forKey: "watchDisplayMode") else {
			print("[Widget] No cached displayMode found, using default")
			return .symbolsOnly
		}

		do {
			let mode = try JSONDecoder().decode(DisplayMode.self, from: data)
			print("[Widget] Loaded displayMode from shared storage: \(mode.rawValue)")
			return mode
		} catch {
			print("[Widget] Failed to decode displayMode: \(error)")
			return .symbolsOnly
		}
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
				.containerBackground(.fill.tertiary, for: .widget)
		}
		.configurationDisplayName("PMS Timetable")
		.description("Your class schedule for the week.")
	}
}

#Preview(as: .accessoryRectangular) {
	PMS_Timetable_Watch_Widgets()
} timeline: {
	TimetableEntry(date: .now, classes: defaultTimetable, displayMode: .symbolsOnly)
}
