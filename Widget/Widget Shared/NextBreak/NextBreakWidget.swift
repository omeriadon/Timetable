import Defaults
import SwiftUI
import WidgetKit

struct NextBreakEntry: TimelineEntry {
	let date: Date
	let breakType: BreakType?
	let interval: SchoolInterval?
	let isPlaceholder: Bool
}

struct NextBreakProvider: TimelineProvider {
	func placeholder(in _: Context) -> NextBreakEntry {
		let now = Date()
		return NextBreakEntry(
			date: now,
			breakType: .recess,
			interval: SchoolInterval(start: now.addingTimeInterval(15 * 60), end: now.addingTimeInterval(35 * 60)),
			isPlaceholder: true
		)
	}

	func getSnapshot(in context: Context, completion: @escaping (NextBreakEntry) -> Void) {
		if context.isPreview {
			completion(placeholder(in: context))
			return
		}
		completion(makeEntry(at: .now))
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<NextBreakEntry>) -> Void) {
		let now = Date()
		let entry = makeEntry(at: now)
		let refreshDate = entry.interval?.end ?? now.addingTimeInterval(60 * 60)
		completion(Timeline(entries: [entry], policy: .after(refreshDate)))
	}

	private func makeEntry(at date: Date) -> NextBreakEntry {
		let adjustedDate = TimetableClock.adjusted(date)
		let next = SchoolStateEngine.nextBreak(after: adjustedDate, subjects: Defaults[.timetable])
		return NextBreakEntry(date: date, breakType: next?.type, interval: next?.interval, isPlaceholder: false)
	}
}

struct NextBreakWidget: Widget {
	let kind = "NextBreak"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: NextBreakProvider()) { entry in
			NextBreakView(entry: entry)
				.containerBackground(.black, for: .widget)
				.widgetURL(URL(string: "timetable://timetable"))
				.redacted(reason: entry.isPlaceholder ? .placeholder : [])
		}
		.configurationDisplayName("Next Break")
		.description("See when your next recess or lunch begins.")
		#if os(watchOS)
			.supportedFamilies([.accessoryRectangular])
		#elseif os(iOS)
			.supportedFamilies([.systemSmall, .accessoryRectangular])
		#else
			.supportedFamilies([.systemSmall])
		#endif
	}
}

#if os(watchOS)
	#Preview(as: .accessoryRectangular) {
		NextBreakWidget()
	} timeline: {
		NextBreakEntry(date: .now, breakType: .recess, interval: SchoolInterval(start: .now.addingTimeInterval(900), end: .now.addingTimeInterval(2100)), isPlaceholder: false)
	}
#else
	#Preview(as: .systemSmall) {
		NextBreakWidget()
	} timeline: {
		NextBreakEntry(date: .now, breakType: .recess, interval: SchoolInterval(start: .now.addingTimeInterval(900), end: .now.addingTimeInterval(2100)), isPlaceholder: false)
	}
#endif
