//
//  WeeklyScheduleWidget.swift
//  Shared Widget
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct WeeklyScheduleWidget: Widget {
	let kind: String = "WeeklySchedule"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			WeeklyScheduleView(entry: entry)
				.containerBackground(.black, for: .widget)
		}
		#if os(watchOS)
		.supportedFamilies([.accessoryRectangular])
		#else
		.supportedFamilies([.systemMedium])
		#endif
		.contentMarginsDisabled()
		.configurationDisplayName("Timetable")
		.description("Your subject schedule for the week.")
	}
}

#if os(watchOS)
	#Preview(as: .accessoryRectangular) {
		WeeklyScheduleWidget()
	} timeline: {
		TimetableEntry(
			date: .now,
			subjects: debugTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#else
	#Preview(as: .systemMedium) {
		WeeklyScheduleWidget()
	} timeline: {
		TimetableEntry(
			date: .now,
			subjects: debugTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#endif
