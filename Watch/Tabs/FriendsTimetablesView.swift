//
//   FriendsTimetablesView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI

struct FriendsTimetablesView: View {
	let friend: FriendSummary
	let timetable: FriendTimetable
	@Default(.schoolCalendar) private var schoolCalendar

	var body: some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			let now = TimetableClock.adjusted(context.date)
			let state = SchoolStateEngine.calculate(
				at: now,
				subjects: timetable.subjects,
				calendar: SchoolCalendarProjection.perthCalendar,
				schoolCalendar: schoolCalendar
			)

			content(state: state, now: now)
				.background {
					WatchSchoolProgressBackground(state: state, now: now)
						.animation(.smooth, value: state)
				}
		}
	}

	private func content(state: SchoolState, now: Date) -> some View {
		let title: String
		let symbol: String
		let color: Color
		var nextText = ""
		var countdownEnd: Date?

		switch state {
			case let .beforeSchool(next):
				title = next.subject.id
				symbol = next.subject.symbol
				color = next.subject.colour.swiftUIColor
				nextText = ""
				countdownEnd = next.interval.start

			case let .lesson(lesson):
				title = lesson.subject.id
				symbol = lesson.subject.symbol
				color = lesson.subject.colour.swiftUIColor
				nextText = lesson.next.title
				countdownEnd = lesson.interval.end

			case let .freePeriod(period):
				title = "Free Period"
				symbol = "studentdesk"
				color = .blue
				nextText = period.next.title
				countdownEnd = period.interval.end

			case let .recess(breakState):
				title = BreakType.recess.description
				symbol = BreakType.recess.symbol
				color = .orange
				nextText = breakState.next.title
				countdownEnd = breakState.interval.end

			case let .lunch(breakState):
				title = BreakType.lunch.description
				symbol = BreakType.lunch.symbol
				color = .orange
				nextText = breakState.next.title
				countdownEnd = breakState.interval.end

			case .afterSchool, .weekend:
				title = "School's Out"
				symbol = "house.fill"
				color = .secondary
				if let next = SchoolStateEngine.nextScheduledSubject(
					after: now,
					subjects: timetable.subjects,
					calendar: SchoolCalendarProjection.perthCalendar,
					schoolCalendar: schoolCalendar
				) {
					nextText = "Next: \(next.subject.id)"
					countdownEnd = next.interval.start
				}

			case .noTimetable:
				title = "No Timetable"
				symbol = "calendar.badge.exclamationmark"
				color = .secondary
		}

		return GeometryReader { geo in
			VStack(alignment: .center) {
				Text(friend.friend.displayName)
					.font(.system(size: 17, weight: .semibold))
					.bold()
					.lineLimit(2)
					.minimumScaleFactor(0.7)
					.multilineTextAlignment(.center)

				Spacer()

				HStack {
					Image(systemName: symbol)
						.contentTransition(.symbolEffect(.replace))
						.symbolEffect(.bounce, value: symbol)
						.font(.headline)
					Text(title)
						.contentTransition(.opacity)
						.animation(.smooth, value: title)
						.font(.system(size: 100))
						.minimumScaleFactor(0.05)
				}
				.bold()

				Spacer()

				if let countdownEnd {
					TimelineView(.periodic(from: .now, by: 1)) { context in
						let remaining = max(0, countdownEnd.timeIntervalSince(context.date))
						let seconds = Int(remaining)

						Text(
							Duration.seconds(seconds),
							format: .time(pattern: .hourMinuteSecond)
						)
						.font(.title3)
						.bold()
						.monospacedDigit()
						.lineLimit(1)
						.contentTransition(.numericText(countsDown: true))
						.animation(.easeInOut(duration: 0.3), value: seconds)
						.padding(.horizontal, 13)
						.padding(.vertical, 8)
//						.glassEffect(
//							.clear.interactive(),
//							in: RoundedRectangle(cornerRadius: 10)
//						)
					}
				}

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
		.padding(.top, 4)
		.dynamicTypeSize(.xSmall)
		.tint(color)
	}
}

#Preview {
	FriendsTimetablesView(
		friend: FriendSummary(
			relationshipID: UUID(),
			friend: FriendProfile(userID: UUID(), displayName: "Adon Omeri", email: nil, appearanceData: nil),
			state: .friends,
			requestedAt: .now,
			acceptedAt: .now,
			timetable: nil,
			locationStatus: nil
		),
		timetable: FriendTimetable(title: "Adon's Timetable", subjects: debugTimetable, updatedAt: .now)
	)
}
