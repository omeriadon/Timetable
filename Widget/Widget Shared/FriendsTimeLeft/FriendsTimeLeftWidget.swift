//
//   FriendsTimeLeftWidget.swift
//   Widget
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI
import WidgetKit

struct FriendsTimeLeftWidget: Widget {
	let kind: String = "FriendsTimeLeft"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			FriendsTimeLeftView(entry: entry, schedules: entry.friendSchedules)
				.containerBackground(.black, for: .widget)
				.widgetURL(URL(string: "timetable://timetable"))
				.redacted(reason: entry.isPlaceholder ? .placeholder : [])
		}
		.configurationDisplayName("Friends' Current Subjects")
		.description("Check what subjects your friends have right now, along with time left.")
		#if os(watchOS)
			.supportedFamilies([.accessoryRectangular])
		#else
			.supportedFamilies([.systemMedium])
		#endif
	}
}

#if os(watchOS)
	#Preview(as: .accessoryRectangular) {
		FriendsTimeLeftWidget()
	} timeline: {
		TimetableEntry(
			date: .now,
			subjects: debugTimetable,
			ownerSchedule: nil,
			friendSchedules: [],
			isPlaceholder: false,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#else
	#Preview(as: .systemMedium) {
		FriendsTimeLeftWidget()
	} timeline: {
		TimetableEntry(
			date: .now,
			subjects: debugTimetable,
			ownerSchedule: nil,
			friendSchedules: [],
			isPlaceholder: false,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#endif
