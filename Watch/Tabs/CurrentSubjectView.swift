//
//  CurrentSubjectView.swift
//  Timetable
//
//  Created by Adon Omeri on 9/8/2026.
//

import SwiftUI

struct WatchTimetableView: View {
	let subjects: [Subject]
	let schoolCalendar: SchoolCalendarProjection

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
				.overlay {
					WatchCurrentTimeMarker(state: state, now: now)
						.allowsHitTesting(false)
				}
		}
	}

	@ViewBuilder
	private func content(state: SchoolState, now: Date) -> some View {
		switch state {
			case let .beforeSchool(next):
				progressView(
					title: next.subject.id,
					symbol: next.subject.symbol,
					color: next.subject.colour.swiftUIColor,
					nextText: nil,
					start: now,
					end: next.interval.start,
					isBeforeSchool: true,
					now: now
				)

			case let .lesson(lesson):
				progressView(
					title: lesson.subject.id,
					symbol: lesson.subject.symbol,
					color: lesson.subject.colour.swiftUIColor,
					nextText: lesson.next.title == "Last Period" ? lesson.next.title : "Next: \(lesson.next.title)",
					start: lesson.interval.start,
					end: lesson.interval.end,
					now: now
				)

			case let .freePeriod(period):
				progressView(
					title: "Free Period",
					symbol: "studentdesk",
					color: .blue,
					nextText: "Next: \(period.next.title)",
					start: period.interval.start,
					end: period.interval.end,
					now: now
				)

			case let .recess(breakState), let .lunch(breakState):
				let type: BreakType = if case .recess = state {
					.recess
				} else {
					.lunch
				}

				progressView(
					title: type.description,
					symbol: type.symbol,
					color: .orange,
					nextText: "Next: \(breakState.next.title)",
					start: breakState.interval.start,
					end: breakState.interval.end,
					now: now
				)

			case .afterSchool, .weekend:
				if let next = SchoolStateEngine.nextScheduledSubject(
					after: now,
					subjects: subjects,
					calendar: SchoolCalendarProjection.perthCalendar,
					schoolCalendar: schoolCalendar
				) {
					progressView(
						title: "School's Out",
						symbol: "house.fill",
						color: .secondary,
						nextText: "Next: \(next.subject.id)",
						start: now,
						end: next.interval.start,
						now: now
					)
				} else {
					ContentUnavailableView("School's Out", systemImage: "house.fill")
				}

			case .noTimetable:
				ContentUnavailableView("No Timetable", systemImage: "calendar.badge.exclamationmark")
		}
	}

	private func progressView(
		title: String,
		symbol: String,
		color: Color,
		nextText: String?,
		start _: Date,
		end: Date,
		isBeforeSchool: Bool = false,
		now: Date
	) -> some View {
		GeometryReader { geometry in
			VStack(alignment: .center) {
				if isBeforeSchool {
					Spacer()

					Text("First Period")
						.font(.caption)

					Image(systemName: symbol)
						.font(.title)
						.bold()
						.contentTransition(.symbolEffect(.replace))
						.symbolEffect(.bounce, value: symbol)

					Text(title)
						.font(.title3.scaled(by: 0.9))
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(maxWidth: geometry.size.width * 0.9)
						.bold()

					Spacer()

					Text(timerInterval: now ... end, countsDown: true, showsHours: true)
						.contentTransition(.numericText(countsDown: true))
						.animation(.easeInOut(duration: 0.5), value: now)
						.font(.title3)
						.lineLimit(1)
						.bold()
						.padding(.horizontal, 15)
						.padding(.vertical, 10)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))

					Spacer()
				} else {
					Spacer()

					Image(systemName: symbol)
						.font(.title3)
						.bold()
						.contentTransition(.symbolEffect(.replace))
						.symbolEffect(.bounce, value: symbol)

					Text(title)
						.font(.title2)
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(maxWidth: geometry.size.width * 0.9)
						.bold()

					Spacer()

					TimelineView(.periodic(from: .now, by: 1)) { context in
						let remaining = max(0, end.timeIntervalSince(context.date))
						let seconds = Int(remaining)

						Text(Duration.seconds(seconds), format: .time(pattern: .hourMinuteSecond))
							.contentTransition(.numericText(countsDown: true))
							.animation(.easeInOut(duration: 0.3), value: seconds)
							.font(.title3)
							.monospacedDigit()
							.lineLimit(1)
							.bold()
							.padding(.horizontal, 10)
							.padding(.vertical, 7)
							.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))
					}

					Spacer()

					Text(nextText ?? "")
						.frame(maxWidth: geometry.size.width * 0.8)
						.font(.caption)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.layoutPriority(1)
				}
			}
			.frame(width: geometry.size.width)
		}
		.padding(.top, 2)
		.padding(.bottom, 6)
		.tint(color)
	}
}
