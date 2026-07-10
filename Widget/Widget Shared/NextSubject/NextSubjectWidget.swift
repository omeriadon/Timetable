import Defaults
import SwiftUI
import WidgetKit

struct NextSubjectEntry: TimelineEntry {
	let date: Date
	let subject: Subject?
	let interval: SchoolInterval?
	let isPlaceholder: Bool
}

struct NextSubjectProvider: TimelineProvider {
	func placeholder(in _: Context) -> NextSubjectEntry {
		let now = Date()
		return NextSubjectEntry(
			date: now,
			subject: debugTimetable.first,
			interval: SchoolInterval(start: now.addingTimeInterval(15 * 60), end: now.addingTimeInterval(75 * 60)),
			isPlaceholder: true
		)
	}

	func getSnapshot(in context: Context, completion: @escaping (NextSubjectEntry) -> Void) {
		completion(context.isPreview ? placeholder(in: context) : makeEntry(at: .now))
	}

	func getTimeline(in _: Context, completion: @escaping (Timeline<NextSubjectEntry>) -> Void) {
		let entry = makeEntry(at: .now)
		let refreshDate = entry.interval?.start ?? Date.now.addingTimeInterval(60 * 60)
		completion(Timeline(entries: [entry], policy: .after(refreshDate)))
	}

	private func makeEntry(at date: Date) -> NextSubjectEntry {
		let adjustedDate = TimetableClock.adjusted(date)
		let next = SchoolStateEngine.nextSubject(after: adjustedDate, subjects: Defaults[.timetable])
		return NextSubjectEntry(date: date, subject: next?.subject, interval: next?.interval, isPlaceholder: false)
	}
}

struct NextSubjectWidget: Widget {
	let kind = "NextSubject"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: NextSubjectProvider()) { entry in
			NextSubjectView(entry: entry)
				.containerBackground(.black, for: .widget)
				.widgetURL(URL(string: "timetable://timetable"))
				.redacted(reason: entry.isPlaceholder ? .placeholder : [])
		}
		.configurationDisplayName("Next Class")
		.description("See your next scheduled class and its start time.")
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
		NextSubjectWidget()
	} timeline: {
		NextSubjectEntry(date: .now, subject: debugTimetable.first, interval: SchoolInterval(start: .now.addingTimeInterval(900), end: .now.addingTimeInterval(4500)), isPlaceholder: false)
	}
#else
	#Preview(as: .systemSmall) {
		NextSubjectWidget()
	} timeline: {
		NextSubjectEntry(date: .now, subject: debugTimetable.first, interval: SchoolInterval(start: .now.addingTimeInterval(900), end: .now.addingTimeInterval(4500)), isPlaceholder: false)
	}
#endif
