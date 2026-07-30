//
//   CurrentSubjectView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI

struct CurrentSubjectView: View {
	@Default(.timetable) private var subjects
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.debugOffset) private var debugOffset

	var body: some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			let now = TimetableClock.adjusted(context.date)
			let state = SchoolStateEngine.calculate(
				at: now,
				subjects: subjects,
				calendar: SchoolCalendarProjection.perthCalendar,
				schoolCalendar: schoolCalendar
			)

			content(state: state, now: now)
				.background {
					WatchSchoolProgressBackground(state: state, now: now)
						.animation(.smooth, value: state)
						.ignoresSafeArea()
				}
		}
		.id(debugOffset)
	}

	@ViewBuilder
	private func content(state: SchoolState, now: Date) -> some View {
		Group {
			switch state {
				case let .beforeSchool(next):
					createProgressView(
						title: next.subject.id,
						symbol: next.subject.symbol,
						color: next.subject.colour.swiftUIColor,
						nextText: nil,
						start: now,
						end: next.interval.start
					)

				case let .lesson(lesson):
					createProgressView(
						title: lesson.subject.id,
						symbol: lesson.subject.symbol,
						color: lesson.subject.colour.swiftUIColor,
						nextText: lesson.next.title,
						start: lesson.interval.start,
						end: lesson.interval.end
					)

				case let .freePeriod(period):
					createProgressView(
						title: "Free Period",
						symbol: "studentdesk",
						color: .blue,
						nextText: period.next.title,
						start: period.interval.start,
						end: period.interval.end
					)

				case let .recess(breakState), let .lunch(breakState):
					let type: BreakType = if case .recess = state {
						.recess
					} else {
						.lunch
					}
					createProgressView(
						title: type.description,
						symbol: type.symbol,
						color: .orange,
						nextText: breakState.next.title,
						start: breakState.interval.start,
						end: breakState.interval.end
					)

				case .afterSchool, .weekend:
					if let next = SchoolStateEngine.nextScheduledSubject(
						after: now,
						subjects: subjects,
						calendar: SchoolCalendarProjection.perthCalendar,
						schoolCalendar: schoolCalendar
					) {
						createProgressView(
							title: "School's Out",
							symbol: "house.fill",
							color: .secondary,
							nextText: "Next: \(next.subject.id)",
							start: now,
							end: next.interval.start
						)
					} else {
						ContentUnavailableView("School's Out", systemImage: "house.fill")
					}

				case .noTimetable:
					ContentUnavailableView("No Timetable", systemImage: "calendar.badge.exclamationmark")
			}
		}
	}

	private func createProgressView(
		title: String,
		symbol: String,
		color: Color,
		nextText: String?,
		start: Date?,
		end: Date?
	) -> some View {
		let now = start ?? TimetableClock.adjusted(.now)
		GeometryReader { geo in
			if let nextText, let end {
				VStack(alignment: .center) {
					Spacer()
					Spacer()

					Image(systemName: symbol)
						.font(.title)
						.bold()
						.contentTransition(.symbolEffect(.replace))
						.symbolEffect(.bounce, value: symbol)

					Text(title)
						.font(.title2.scaled(by: 0.9))
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(maxWidth: geo.size.width * 0.9)
						.bold()
						.contentTransition(.opacity)
						.animation(.smooth, value: title)

					Spacer()

					Text(timerInterval: now ... end, countsDown: true, showsHours: true)
						.contentTransition(.numericText())
						.animation(.easeInOut, value: now)
						.font(.title2)
						.lineLimit(1)
						.bold()
						.padding(.horizontal, 15)
						.padding(.vertical, 10)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))

					Spacer()

					Text(nextText)
						.frame(maxWidth: geo.size.width * 0.8)
						.font(.caption)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.layoutPriority(1)

					Spacer()
						.frame(height: geo.size.height * 0.1)
				}
				.frame(width: geo.size.width)
			} else {
				VStack(alignment: .center) {
					Spacer()
					Spacer()

					Text("Before School")
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.layoutPriority(1)

					Spacer()

					Text("First Period:")
						.font(.caption2)
						.foregroundStyle(.secondary)

					Image(systemName: symbol)
						.font(.title)
						.bold()
						.contentTransition(.symbolEffect(.replace))
						.symbolEffect(.bounce, value: symbol)

					Text(title)
						.font(.title2.scaled(by: 0.9))
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(maxWidth: geo.size.width * 0.9)
						.bold()
						.contentTransition(.opacity)
						.animation(.smooth, value: title)

					Spacer()

					let targetDate = end ?? now
					Text(timerInterval: now ... targetDate, countsDown: true, showsHours: true)
						.contentTransition(.numericText(countsDown: true))
						.animation(.easeInOut(duration: 0.5), value: now)
						.font(.title2)
						.lineLimit(1)
						.bold()
						.padding(.horizontal, 15)
						.padding(.vertical, 10)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))

					Spacer()
						.frame(height: geo.size.height * 0.1)
				}
			}
		}
		.ignoresSafeArea()
		.tint(color)
	}
}

#Preview {
	CurrentSubjectView()
		.monospaced()
}
