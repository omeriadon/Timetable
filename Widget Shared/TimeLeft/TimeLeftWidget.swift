//
//  TimeLeftWidget.swift
//  Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct TimeLeftWidget: Widget {
	let kind: String = "TimeLeft"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			let subjectLookup = TimetableLayout.subjectLookup(for: entry.subject)
			let state = getSchoolState(at: entry.date, subjectLookup: subjectLookup)

			let background: Color = switch state {
				case let .beforeSchool(next):
					next.colour.swiftUIColor
				case let .inClass(current, _, _):
					current?.colour.swiftUIColor ?? .black
				case .inBreak:
					.orange
				case .outsideSchool:
					.black
			}

			TimeLeftView(entry: entry, state: state)
				.containerBackground(background, for: .widget)
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
			subject: defaultTimetable,
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
			subject: defaultTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	})
#endif
