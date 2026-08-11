
import Defaults
import SwiftUI
import WidgetKit

#if canImport(UIKit)
	import UIKit
#endif

struct TimetableSummaryWidget: Widget {
	let kind = "TimetableSummary"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			TimetableSummaryView(entry: entry)
				.containerBackground(for: .widget) {
					Image("backgroundPaper")
						.resizable()
						.aspectRatio(contentMode: .fill)
				}
				.widgetURL(AppRoute.timetable(.root).url)
				.redacted(reason: entry.isPlaceholder ? .placeholder : [])
		}
		.configurationDisplayName("Timetable Summary")
		.description("Your current class, friend priorities, and upcoming events.")
		.supportedFamilies([.systemLarge])
	}
}

#Preview(as: .systemLarge) {
	TimetableSummaryWidget()
} timeline: {
	TimetableEntry(
		date: .now,
		subjects: debugTimetable,
		ownerSchedule: scheduleItem(name: "You", subjects: debugTimetable, at: .now, schoolCalendar: Defaults[.schoolCalendar]),
		friendSchedules: [
			scheduleItem(name: "Alex", subjects: debugTimetable, at: .now, schoolCalendar: Defaults[.schoolCalendar]),
		],
		upcomingEvents: [],
		isPlaceholder: false,
		relevance: nil
	)
}
