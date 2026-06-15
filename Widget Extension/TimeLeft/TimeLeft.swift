//
//  TimeLeft.swift
//  Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct TimeLeftWidgetEntryView: View {
	var entry: Provider.Entry

	var body: some View {
		TimeLeftView(entry: entry)
	}
}

struct TimeLeftWidget: Widget {
	let kind: String = "TimeLeft"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			TimeLeftView(entry: entry)
				.containerBackground(.ultraThinMaterial, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Time Left in Subject")
		.description("Check how much time left until the end of this period.")
		#if os(watchOS)
			.supportedFamilies([.accessoryRectangular])
		#else
			.supportedFamilies([.systemMedium])
		#endif
	}
}

#if os(watchOS)
	#Preview(as: .accessoryRectangular, widget: {
		TimeLeftWidget()
	}, timeline: {
		TimetableEntry(
			date: Date(),
			classes: defaultTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	})
#else
	#Preview(as: .systemMedium, widget: {
		TimeLeftWidget()
	}, timeline: {
		TimetableEntry(
			date: Date(),
			classes: defaultTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	})
#endif
