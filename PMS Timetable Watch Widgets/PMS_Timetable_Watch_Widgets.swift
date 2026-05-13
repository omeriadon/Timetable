//
//  PMS_Timetable_Watch_Widgets.swift
//  PMS Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct PMS_Timetable_Watch_WidgetsEntryView: View {
	var entry: Provider.Entry

	var body: some View {
		Main_Widget_View(classes: entry.classes, displayMode: entry.displayMode)
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
