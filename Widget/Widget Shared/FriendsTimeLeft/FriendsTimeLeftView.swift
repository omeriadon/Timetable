//
//   FriendsTimeLeftView.swift
//   Widget
//
//   Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct FriendsTimeLeftView: View {
	let entry: TimetableEntry

	let schedules: [ScheduleItem]

	var body: some View {
		let owner = entry.ownerSchedule ?? ScheduleItem(
			name: "You",
			currentState: .noTimetable,
			nextScheduledSubject: nil,
			backgroundColour: .black,
			profile: nil,
			futureStatus: nil
		)

		return VStack(alignment: .leading, spacing: 0) {
			FriendsCurrentRow(schedule: owner, now: TimetableClock.adjusted(entry.date))
				.padding(7)
				.padding(.leading, 4)
				.padding(.trailing, 2)
				.overlay {
					ContainerRelativeShape()
						.stroke(.primary.opacity(0.7), lineWidth: 1)
				}

			Spacer()

			ForEach(Array(schedules.prefix(3).enumerated()), id: \.element.id) { index, schedule in
				if index > 0 {
					Divider()
				}
				FriendsScheduleRow(schedule: schedule)
			}
		}
		.widgetAppFontDesign()
		.dynamicTypeSize(.medium)
	}
}

struct FriendsCurrentRow: View {
	let schedule: ScheduleItem
	let now: Date

	var body: some View {
		HStack(alignment: .center, spacing: 8) {
			currentTimer
			Spacer()
			VStack(alignment: .leading, spacing: 2) {
				Text(nextText)
					.font(.system(size: 11, weight: .regular, design: Defaults[.accountSettings].appFontDesign.swiftUIFontDesign))
					.foregroundStyle(.secondary)
					.lineLimit(1)

				Label(title, systemImage: symbol)
					.font(.system(size: 14, weight: .semibold, design: Defaults[.accountSettings].appFontDesign.swiftUIFontDesign))
					.lineLimit(2)
			}
		}
	}

	@ViewBuilder
	private var currentTimer: some View {
		if let target = countdownTarget {
			Text(timerInterval: now ... target, countsDown: true, showsHours: true)
				.font(.system(size: 18, weight: .regular, design: Defaults[.accountSettings].appFontDesign.swiftUIFontDesign))
				.monospacedDigit()
		} else {
			Text("—")
				.font(.system(size: 18, design: Defaults[.accountSettings].appFontDesign.swiftUIFontDesign))
		}
	}

	private var countdownTarget: Date? {
		switch schedule.currentState {
			case let .beforeSchool(next): next.interval.start
			case let .lesson(lesson): lesson.interval.end
			case let .freePeriod(period): period.interval.end
			case let .recess(state), let .lunch(state): state.interval.end
			case .afterSchool, .weekend: schedule.nextScheduledSubject?.interval.start
			case .noTimetable: nil
		}
	}

	private var title: String {
		switch schedule.currentState {
			case let .beforeSchool(next): next.subject.id.capitalized
			case let .lesson(lesson): lesson.subject.id.capitalized
			case .freePeriod: "Free Period"
			case .recess: BreakType.recess.description
			case .lunch: BreakType.lunch.description
			case .afterSchool, .weekend: "School's Out"
			case .noTimetable: "No Timetable"
		}
	}

	private var symbol: String {
		switch schedule.currentState {
			case let .beforeSchool(next): next.subject.symbol
			case let .lesson(lesson): lesson.subject.symbol
			case .freePeriod: "studentdesk"
			case .recess: BreakType.recess.symbol
			case .lunch: BreakType.lunch.symbol
			case .afterSchool, .weekend: "house.fill"
			case .noTimetable: "calendar.badge.exclamationmark"
		}
	}

	private var nextText: String {
		switch schedule.currentState {
			case let .beforeSchool(next): "Next: \(next.subject.id.capitalized)"
			case let .lesson(lesson): lesson.next.title
			case let .freePeriod(period): period.next.title
			case let .recess(state), let .lunch(state): state.next.title
			case .afterSchool, .weekend:
				if let next = schedule.nextScheduledSubject {
					"Next: \(next.subject.id.capitalized)"
				} else {
					"No more classes"
				}
			case .noTimetable: "Sync a timetable"
		}
	}
}

private struct FriendsScheduleRow: View {
	let schedule: ScheduleItem

	var body: some View {
		HStack(spacing: 8) {
			Text(schedule.name)
				.font(.system(size: 13, weight: .regular, design: Defaults[.accountSettings].appFontDesign.swiftUIFontDesign))

			Spacer()

			Label(title, systemImage: symbol)
				.font(.system(size: 13, weight: .medium, design: Defaults[.accountSettings].appFontDesign.swiftUIFontDesign))
				.lineLimit(1)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 5)
	}

	private var title: String {
		switch schedule.currentState {
			case let .beforeSchool(next): next.subject.id.capitalized
			case let .lesson(lesson): lesson.subject.id.capitalized
			case .freePeriod: "Free Period"
			case .recess: BreakType.recess.description
			case .lunch: BreakType.lunch.description
			case .afterSchool, .weekend: "School's Out"
			case .noTimetable: "No Timetable"
		}
	}

	private var symbol: String {
		switch schedule.currentState {
			case let .beforeSchool(next): next.subject.symbol
			case let .lesson(lesson): lesson.subject.symbol
			case .freePeriod: "studentdesk"
			case .recess: BreakType.recess.symbol
			case .lunch: BreakType.lunch.symbol
			case .afterSchool, .weekend: "house.fill"
			case .noTimetable: "calendar.badge.exclamationmark"
		}
	}
}
