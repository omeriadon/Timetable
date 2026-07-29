import Defaults
import SwiftUI
import WidgetKit

struct TimetableSummaryWidget: Widget {
	let kind = "TimetableSummary"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			TimetableSummaryView(entry: entry)
				.containerBackground(.black, for: .widget)
				.widgetURL(URL(string: "timetable://timetable"))
				.redacted(reason: entry.isPlaceholder ? .placeholder : [])
		}
		.configurationDisplayName("Timetable Summary")
		.description("Your current class, friend priorities, and upcoming events.")
		.supportedFamilies([.systemLarge])
	}
}

private struct TimetableSummaryView: View {
	let entry: TimetableEntry

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			header

			Divider()

			friendSection

			if !entry.upcomingEvents.isEmpty {
				Divider()
				eventSection
			}
		}
		.padding()
		.foregroundStyle(.white)
		.dynamicTypeSize(.medium)
	}

	private var header: some View {
		HStack(alignment: .center, spacing: 10) {
			Image(systemName: ownerSymbol)
				.font(.title2)
				.frame(width: 28)

			VStack(alignment: .leading, spacing: 2) {
				Text("You")
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				Text(ownerTitle)
					.font(.headline)
					.lineLimit(1)
			}

			Spacer()

			if let countdown = countdownTarget {
				Text(timerInterval: TimetableClock.adjusted(entry.date) ... countdown, countsDown: true, showsHours: true)
					.font(.headline.monospacedDigit())
					.lineLimit(1)
			}
		}
	}

	private var friendSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Label("Friends", systemImage: "person.2.fill")
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)

			ForEach(entry.friendSchedules.prefix(3)) { schedule in
				HStack(spacing: 8) {
					Image(systemName: symbol(for: schedule.currentState))
						.frame(width: 18)
						.foregroundStyle(schedule.backgroundColour)
					Text(schedule.name)
						.font(.subheadline.weight(.medium))
						.lineLimit(1)
					Spacer()
					Text(title(for: schedule.currentState))
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
		}
	}

	private var eventSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Label("Upcoming Events", systemImage: "calendar")
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)

			ForEach(entry.upcomingEvents) { event in
				HStack(spacing: 8) {
					Image(systemName: event.symbol)
						.frame(width: 18)
					Text(event.title)
						.font(.subheadline.weight(.medium))
						.lineLimit(1)
					Spacer()
					Text(event.date.displayLabel)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
		}
	}

	private var ownerTitle: String {
		guard let schedule = entry.ownerSchedule else {
			return "No Timetable"
		}
		return title(for: schedule.currentState)
	}

	private var ownerSymbol: String {
		guard let schedule = entry.ownerSchedule else {
			return "calendar.badge.exclamationmark"
		}
		return symbol(for: schedule.currentState)
	}

	private var countdownTarget: Date? {
		guard let schedule = entry.ownerSchedule else {
			return nil
		}

		switch schedule.currentState {
			case let .beforeSchool(next):
				return next.interval.start
			case let .lesson(lesson):
				return lesson.interval.end
			case let .freePeriod(period):
				return period.interval.end
			case let .recess(state), let .lunch(state):
				return state.interval.end
			case .afterSchool, .weekend:
				return schedule.nextScheduledSubject?.interval.start
			case .noTimetable:
				return nil
		}
	}

	private func title(for state: SchoolState) -> String {
		switch state {
			case let .beforeSchool(next):
				return next.subject.id
			case let .lesson(lesson):
				return lesson.subject.id
			case .freePeriod:
				return "Free Period"
			case .recess:
				return BreakType.recess.description
			case .lunch:
				return BreakType.lunch.description
			case .afterSchool, .weekend:
				return "School's Out"
			case .noTimetable:
				return "No Timetable"
		}
	}

	private func symbol(for state: SchoolState) -> String {
		switch state {
			case let .beforeSchool(next):
				return next.subject.symbol
			case let .lesson(lesson):
				return lesson.subject.symbol
			case .freePeriod:
				return "studentdesk"
			case .recess:
				return BreakType.recess.symbol
			case .lunch:
				return BreakType.lunch.symbol
			case .afterSchool, .weekend:
				return "house.fill"
			case .noTimetable:
				return "calendar.badge.exclamationmark"
		}
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
