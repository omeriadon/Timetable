//
//   WeeklyScheduleWidget.swift
//   Widget
//
//   Created by Adon Omeri on 13/6/2026.
//

import AppIntents
import Defaults
import SwiftUI
import WidgetKit

struct WeeklyScheduleWidget: Widget {
	let kind: String = "WeeklySchedule"

	var body: some WidgetConfiguration {
		AppIntentConfiguration(
			kind: kind,
			intent: WeeklyScheduleConfigurationIntent.self,
			provider: WeeklyScheduleProvider()
		) { entry in
			WeeklyScheduleView(entry: entry)
				.containerBackground(for: .widget) {
					Image("backgroundPaper")
						.resizable()
						.aspectRatio(contentMode: .fill)
				}
				.widgetURL(AppRoute.timetable(.root).url)
				.redacted(reason: entry.isPlaceholder ? .placeholder : [])
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

struct WeeklyScheduleEntry: TimelineEntry {
	let date: Date
	let displayName: String
	let subjects: [Subject]
	let isPlaceholder: Bool
	let relevance: TimelineEntryRelevance?
}

struct WeeklyScheduleProvider: AppIntentTimelineProvider {
	func placeholder(in _: Context) -> WeeklyScheduleEntry {
		WeeklyScheduleEntry(
			date: .now,
			displayName: "You",
			subjects: debugTimetable,
			isPlaceholder: true,
			relevance: nil
		)
	}

	func snapshot(for configuration: WeeklyScheduleConfigurationIntent, in context: Context) async -> WeeklyScheduleEntry {
		if context.isPreview {
			return placeholder(in: context)
		}
		return await entry(for: configuration, at: .now, isPlaceholder: false)
	}

	func timeline(for configuration: WeeklyScheduleConfigurationIntent, in _: Context) async -> Timeline<WeeklyScheduleEntry> {
		let now = Date()
		let entry = await entry(for: configuration, at: now, isPlaceholder: false)
		let nextMidnight = Calendar.current.nextDate(
			after: now,
			matching: DateComponents(hour: 0, minute: 0),
			matchingPolicy: .nextTime
		) ?? now.addingTimeInterval(6 * 60 * 60)
		return Timeline(entries: [entry], policy: .after(nextMidnight))
	}

	func recommendations() -> [AppIntentRecommendation<WeeklyScheduleConfigurationIntent>] {
		let intent = WeeklyScheduleConfigurationIntent()
		intent.person = PersonTimetableEntity(id: PersonTimetableEntity.ownerID, displayName: "You")
		return [AppIntentRecommendation(intent: intent, description: "Your timetable")]
	}

	@MainActor
	private func entry(
		for _: WeeklyScheduleConfigurationIntent,
		at date: Date,
		isPlaceholder: Bool
	) -> WeeklyScheduleEntry {
		WeeklyScheduleEntry(
			date: date,
			displayName: "You",
			subjects: Defaults[.timetable],
			isPlaceholder: isPlaceholder,
			relevance: nil
		)
	}
}

#if os(watchOS)
	#Preview(as: .accessoryRectangular) {
		WeeklyScheduleWidget()
	} timeline: {
		WeeklyScheduleEntry(
			date: .now,
			displayName: "You",
			subjects: debugTimetable,
			isPlaceholder: false,
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
		WeeklyScheduleEntry(
			date: .now,
			displayName: "You",
			subjects: debugTimetable,
			isPlaceholder: false,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#endif
