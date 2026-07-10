//
//   FriendsTimeLeftView.swift
//   Widget
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI
import WidgetKit

let mathematics = Subject(
	id: "mathematics",
	symbol: "function",
	colour: RGBAColor(hexString: "#3B82F6"),
	slots: [Slot(0, 0), Slot(2, 1), Slot(4, 2)]
)

let english = Subject(
	id: "english",
	symbol: "book",
	colour: RGBAColor(hexString: "#EF4444"),
	slots: [Slot(1, 0), Slot(3, 2), Slot(4, 4)]
)

let science = Subject(
	id: "science",
	symbol: "atom",
	colour: RGBAColor(hexString: "#10B981"),
	slots: [Slot(0, 2), Slot(2, 3), Slot(3, 0)]
)

let history = Subject(
	id: "history",
	symbol: "building.columns.fill",
	colour: RGBAColor(hexString: "#F59E0B"),
	slots: [Slot(1, 1), Slot(3, 3)]
)

let geography = Subject(
	id: "geography",
	symbol: "globe.europe.africa.fill",
	colour: RGBAColor(hexString: "#06B6D4"),
	slots: [Slot(0, 4), Slot(2, 0)]
)

let physics = Subject(
	id: "physics",
	symbol: "bolt.fill",
	colour: RGBAColor(hexString: "#8B5CF6"),
	slots: [Slot(1, 4), Slot(4, 1)]
)

let chemistry = Subject(
	id: "chemistry",
	symbol: "testtube.2",
	colour: RGBAColor(hexString: "#EC4899"),
	slots: [Slot(0, 1), Slot(2, 4)]
)

let computerScience = Subject(
	id: "computer-science",
	symbol: "desktopcomputer",
	colour: RGBAColor(hexString: "#64748B"),
	slots: [Slot(1, 3), Slot(3, 1), Slot(4, 0)]
)

let art = Subject(
	id: "art",
	symbol: "paintpalette.fill",
	colour: RGBAColor(hexString: "#F97316"),
	slots: [Slot(2, 2), Slot(4, 3)]
)

let pe = Subject(
	id: "physical-education",
	symbol: "figure.run",
	colour: RGBAColor(hexString: "#22C55E"),
	slots: [Slot(0, 3), Slot(3, 4)]
)

struct FriendsTimeLeftView: View {
	let entry: TimetableEntry

	let schedules: [ScheduleItem]

	var body: some View {
		let owner = entry.ownerSchedule ?? ScheduleItem(name: "You", currentState: .noTimetable, backgroundColour: .black)

		return VStack(alignment: .leading, spacing: 0) {
			FriendsCurrentRow(schedule: owner, now: TimetableClock.adjusted(entry.date))
				.padding(7)
				.padding(.leading, 4)
				.padding(.trailing, 2)
				.overlay {
					ContainerRelativeShape()
						.stroke(.white.opacity(0.7), lineWidth: 1)
				}

			Spacer()

			ForEach(Array(schedules.prefix(3).enumerated()), id: \.element.id) { index, schedule in
				if index > 0 {
					Divider()
				}
				FriendsScheduleRow(schedule: schedule)
			}
		}
		.foregroundStyle(.white)
		.fontDesign(.monospaced)
		.dynamicTypeSize(.medium)
	}
}

private struct FriendsCurrentRow: View {
	let schedule: ScheduleItem
	let now: Date

	var body: some View {
		HStack(alignment: .center, spacing: 8) {
			currentTimer
			Spacer()
			VStack(alignment: .leading, spacing: 2) {
				Text(nextText)
					.font(.system(size: 11, weight: .regular, design: .monospaced))
					.foregroundStyle(.secondary)
					.lineLimit(1)

				Label(title, systemImage: symbol)
					.font(.system(size: 14, weight: .semibold, design: .monospaced))
					.lineLimit(2)
			}
		}
	}

	@ViewBuilder
	private var currentTimer: some View {
		switch schedule.currentState {
			case let .lesson(lesson):
				Text(timerInterval: now ... lesson.interval.end, countsDown: true, showsHours: false)
					.font(.system(size: 18, weight: .regular, design: .monospaced))
					.monospacedDigit()
			case let .freePeriod(period):
				Text(timerInterval: now ... period.interval.end, countsDown: true, showsHours: false)
					.font(.system(size: 18, weight: .regular, design: .monospaced))
					.monospacedDigit()
			case let .recess(state), let .lunch(state):
				Text(timerInterval: now ... state.interval.end, countsDown: true, showsHours: false)
					.font(.system(size: 18, weight: .regular, design: .monospaced))
					.monospacedDigit()
			case .afterSchool, .weekend, .noTimetable:
				Text("—")
					.font(.system(size: 18, design: .monospaced))
			case let .beforeSchool(next):
				Text(timerInterval: now ... next.interval.start, countsDown: true)
					.font(.system(size: 18, design: .monospaced))
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
			case let .beforeSchool(next): "First Period: \(next.subject.id.capitalized)"
			case let .lesson(lesson): lesson.next.title
			case let .freePeriod(period): period.next.title
			case let .recess(state), let .lunch(state): state.next.title
			case .afterSchool, .weekend: "No more classes"
			case .noTimetable: "Sync a timetable"
		}
	}
}

private struct FriendsScheduleRow: View {
	let schedule: ScheduleItem

	var body: some View {
		HStack(spacing: 8) {
			Text(schedule.name)
				.font(.system(size: 13, weight: .regular, design: .monospaced))

			Spacer()

			Label(title, systemImage: symbol)
				.font(.system(size: 13, weight: .medium, design: .monospaced))
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
