//
//  Timetable_Watch_Widgets_Time_Left.swift
//  Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct Timetable_Watch_WidgetsEntryView_Time_Left: View {
	var entry: Provider.Entry

	var body: some View {
		Time_Left_Widget_View(entry: entry)
	}
}

struct Timetable_Watch_Widgets_Time_Left: Widget {
	let kind: String = "Timetable_Watch_Widgets_Time_Left"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			Timetable_Watch_WidgetsEntryView_Time_Left(entry: entry)
				.containerBackground(.ultraThinMaterial, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Time Left in Subject")
		.description("Check how much time left until the end of this period.")
		.supportedFamilies([.accessoryRectangular])
	}
}

#Preview(as: .accessoryRectangular) {
	Timetable_Watch_Widgets_Time_Left()
} timeline: {
	TimetableEntry(
		date: Date(),
		classes: defaultTimetable,
		displayMode: .symbolsOnly,
		relevance: TimelineEntryRelevance(
			score: 1.0,
			duration: 60 * 60
		)
	)
}
