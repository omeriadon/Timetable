//
//   CurrentSubjectView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Combine
import Defaults
import SwiftUI

struct CurrentSubjectView: View {
	@Default(.timetable) private var subjects

	let now: Date

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	var body: some View {
		let state = SchoolStateEngine.calculate(at: now, subjects: subjects)

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
					let type: BreakType = if case .recess = state { .recess } else { .lunch }
					createProgressView(
						title: type.description,
						symbol: type.symbol,
						color: .orange,
						nextText: breakState.next.title,
						start: breakState.interval.start,
						end: breakState.interval.end
					)

				case .afterSchool, .weekend:
					VStack(alignment: .center) {
						Label("School's Out", systemImage: "house.fill")
							.font(.title3)
							.padding(.bottom)

						if let next = SchoolStateEngine.nextSubjectOnFollowingSchoolDay(after: now, subjects: subjects) {
							Text("Next: \(next.subject.id)")
								.foregroundStyle(.secondary)
						} else {
							Text("No more subjects")
								.foregroundStyle(.secondary)
						}
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
		start _: Date?,
		end: Date?
	) -> some View {
		GeometryReader { geo in
			if let nextText, let end {
				// 2. Calculate remaining time using the synchronized parent 'now'
				let remaining = max(0, end.timeIntervalSince(now))
				let hours = Int(remaining) / 3600
				let minutes = (Int(remaining) % 3600) / 60
				let seconds = Int(remaining) % 60

				let timeString = hours > 0
					? String(format: "%d:%02d:%02d", hours, minutes, seconds)
					: String(format: "%02d:%02d", minutes, seconds)

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

					Text(timeString)
						.contentTransition(.numericText(countsDown: true))
						.animation(.easeInOut(duration: 0.5), value: timeString)
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
					Text(timerInterval: now ... targetDate, countsDown: true)
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
	CurrentSubjectView(now: TimetableClock.now)
		.monospaced()
}
