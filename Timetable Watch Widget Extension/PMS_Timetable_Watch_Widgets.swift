//
//  Timetable_Watch_Widgets.swift
//  Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct Timetable_Watch_WidgetsEntryView: View {
	var entry: Provider.Entry

	var body: some View {
		Main_Widget_View(classes: entry.classes)
	}
}

struct Timetable_Watch_Widgets: Widget {
	let kind: String = "Timetable_Watch_Widgets"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			Timetable_Watch_WidgetsEntryView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Timetable")
		.description("Your class schedule for the week.")
	}
}

#Preview(as: .accessoryRectangular) {
	Timetable_Watch_Widgets()
} timeline: {
	TimetableEntry(
		date: .now,
		classes: defaultTimetable,
		relevance: TimelineEntryRelevance(
			score: 1.0,
			duration: 60 * 60
		)
	)
}
