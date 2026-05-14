//
//  PMS_Timetable_Watch_Widgets_Time_Left.swift
//  PMS Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct PMS_Timetable_Watch_WidgetsEntryView_Time_Left: View {
	var entry: Provider.Entry

	var body: some View {
		Time_Left_Widget_View(entry: entry)
	}
}

struct PMS_Timetable_Watch_Widgets_Time_Left: Widget {
	let kind: String = "PMS_Timetable_Watch_Widgets_Time_Left"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			PMS_Timetable_Watch_WidgetsEntryView_Time_Left(entry: entry)
				.containerBackground(.ultraThinMaterial, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Time Left in Subject")
		.description("Check how much time left until the end of this period.")
		.supportedFamilies([.accessoryRectangular])
	}
}

#Preview(as: .accessoryRectangular) {
	PMS_Timetable_Watch_Widgets_Time_Left()
} timeline: {
	TimetableEntry(
		date: Date(),
		classes: defaultTimetable,
		displayMode: .symbolsOnly
	)
}
