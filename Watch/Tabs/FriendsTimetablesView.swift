//
//   FriendsTimetablesView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Combine
import Defaults
import SwiftUI

struct FriendsTimetablesView: View {
	let receivedTimetable: ReceivedTimetable

	@State private var now = TimetableClock.now
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	var body: some View {
		let state = SchoolStateEngine.calculate(at: now, subjects: receivedTimetable.subjects)

		let title: String
		let symbol: String
		let color: Color
		var nextText = ""

		switch state {
			case let .beforeSchool(next):
				title = next.subject.id
				symbol = next.subject.symbol
				color = next.subject.colour.swiftUIColor
				nextText = ""

			case let .lesson(lesson):
				title = lesson.subject.id
				symbol = lesson.subject.symbol
				color = lesson.subject.colour.swiftUIColor
				nextText = lesson.next.title

			case let .freePeriod(period):
				title = "Free Period"
				symbol = "studentdesk"
				color = .blue
				nextText = period.next.title

			case let .recess(breakState):
				title = BreakType.recess.description
				symbol = BreakType.recess.symbol
				color = .orange
				nextText = breakState.next.title

			case let .lunch(breakState):
				title = BreakType.lunch.description
				symbol = BreakType.lunch.symbol
				color = .orange
				nextText = breakState.next.title

			case .afterSchool, .weekend:
				title = "School's Out"
				symbol = "house.fill"
				color = .secondary

			case .noTimetable:
				title = "No Timetable"
				symbol = "calendar.badge.exclamationmark"
				color = .secondary
		}

		return GeometryReader { geo in
			VStack(alignment: .center) {
				Text(receivedTimetable.sender)
					.font(.title2)
					.bold()
					.lineLimit(2)
					.minimumScaleFactor(0.8)

				Spacer()

				HStack {
					Image(systemName: symbol)
					Text(title)
				}
				.font(.title2.scaled(by: 0.9))
				.bold()

				Spacer()

				let isAfterSchoolStart = now >= Calendar.current.date(
					bySettingHour: SchoolStateEngine.schoolStart.hour,
					minute: SchoolStateEngine.schoolStart.minute,
					second: 0,
					of: now
				)!

				Text(!nextText.isEmpty ? nextText : isAfterSchoolStart ? "Done for the day" : "")
					.font(.caption)
					.foregroundStyle(.secondary)
					.frame(maxWidth: geo.size.width * 0.8)
					.multilineTextAlignment(.center)

				Spacer()
			}
			.frame(width: geo.size.width)
		}
		.dynamicTypeSize(.xSmall)
		.tint(color)
		.onReceive(timer) { value in
			withAnimation(.default) {
				now = TimetableClock.adjusted(value)
			}
		}
	}
}

#Preview {
	FriendsTimetablesView(
		receivedTimetable: ReceivedTimetable(
			sender: "Adon Omeri",
			subjects: debugTimetable,
			receivedAt: Date()
		)
	)
	.monospaced()
}
