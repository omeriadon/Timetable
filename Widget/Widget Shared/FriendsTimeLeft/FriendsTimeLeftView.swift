//
//  FriendsTimeLeftView.swift
//  Widget Shared
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct ScheduleItem: Identifiable {
	var id: String {
		name
	}

	let name: String

	let currentState: SchoolState
	let backgroundColour: Color
}

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

	init(entry: TimetableEntry, schedules: [ScheduleItem]) {
		self.entry = entry

		if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
			self.schedules = [
				ScheduleItem(
					name: "Alex",
					currentState: .beforeSchool(next: english),
					backgroundColour: .red
				),

				ScheduleItem(
					name: "Emily",
					currentState: .inBreak(
						breakType: .recess,
						nextText: "Science",
						info: (start: Date(), end: Date().addingTimeInterval(20 * 60))
					),
					backgroundColour: .green
				),

				ScheduleItem(
					name: "Noah",
					currentState: .inClass(
						current: history,
						nextText: "Geography",
						info: (start: Date(), end: Date().addingTimeInterval(55 * 60))
					),
					backgroundColour: .orange
				),

				ScheduleItem(
					name: "Sophia",
					currentState: .outsideSchool,
					backgroundColour: .purple
				),

				ScheduleItem(
					name: "Liam",
					currentState: .inBreak(
						breakType: .lunch,
						nextText: "Physics",
						info: (start: Date(), end: Date().addingTimeInterval(40 * 60))
					),
					backgroundColour: .pink
				),

				ScheduleItem(
					name: "Olivia",
					currentState: .inClass(
						current: chemistry,
						nextText: "Computer Science",
						info: (start: Date(), end: Date().addingTimeInterval(50 * 60))
					),
					backgroundColour: .cyan
				),

				ScheduleItem(
					name: "Ethan",
					currentState: .beforeSchool(next: pe),
					backgroundColour: .mint
				),

				ScheduleItem(
					name: "Mia",
					currentState: .inClass(
						current: art,
						nextText: "Home",
						info: (start: Date(), end: Date().addingTimeInterval(45 * 60))
					),
					backgroundColour: .yellow
				),

				ScheduleItem(
					name: "Lucas",
					currentState: .outsideSchool,
					backgroundColour: .gray
				),
			]
		} else {
			self.schedules = schedules
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text("You")

				Spacer()

				let subjectLookup = TimetableLayout.subjectLookup(for: entry.subjects)
				let state = getSchoolState(at: Date().addingTimeInterval(debugOffset), subjectLookup: subjectLookup)

				switch state {
					case let .beforeSchool(next):
						Text("before school")

					case let .inClass(current, nextText, info):
						Text(timerInterval: Date.now.addingTimeInterval(debugOffset) ... info.end, countsDown: true)
							.contentTransition(.numericText(countsDown: true))

					case let .inBreak(breakType, nextText, info):
						Text(timerInterval: Date.now.addingTimeInterval(debugOffset) ... info.end, countsDown: true)
							.contentTransition(.numericText(countsDown: true))

					case .outsideSchool:
						Text("after")
				}
			}
			.frame(height: 40)
			.padding(.horizontal, 15)

			ForEach(schedules.prefix(4)) { schedule in
				HStack(spacing: 0) {
					Text(schedule.name)

					Spacer()

					Group {
						switch schedule.currentState {
							case let .beforeSchool(next: next):
								Text(next.id.capitalized)

							case let .inBreak(breakType: breakType, nextText: nextText, info: info):
								Label(breakType.description, systemImage: breakType.symbol)
									.imageScale(.small)

							case let .inClass(current: current, nextText: nextText, info: info):
								Label(current?.id ?? "unknown", systemImage: current?.symbol ?? "circle")

							case .outsideSchool:
								Label("Outside School Time", systemImage: "zzz")
						}
					}
					.animation(.easeInOut, value: schedule.id)
					.font(.callout)
				}
				.frame(maxHeight: 37)
				.padding(.horizontal, 15)
				.background {
					schedule.backgroundColour
				}
			}

			Spacer(minLength: 0)
		}
		.foregroundStyle(.white)
		.monospaced()
		.dynamicTypeSize(.medium)
	}
}
