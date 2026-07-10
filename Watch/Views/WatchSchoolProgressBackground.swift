import IrregularGradient
import SwiftUI

struct WatchSchoolProgressBackground: View {
	let state: SchoolState
	let now: Date

	var body: some View {
		switch state {
			case let .beforeSchool(next):
				WatchProgressFill(color: next.subject.colour.swiftUIColor, now: now)
			case let .lesson(lesson):
				WatchProgressFill(
					color: lesson.subject.colour.swiftUIColor,
					start: lesson.interval.start,
					end: lesson.interval.end,
					now: now
				)
			case let .freePeriod(period):
				WatchProgressFill(color: .blue, start: period.interval.start, end: period.interval.end, now: now)
			case let .recess(state), let .lunch(state):
				WatchProgressFill(
					color: .black,
					start: state.interval.start,
					end: state.interval.end,
					now: now,
					isBreak: true
				)
			case .afterSchool, .weekend, .noTimetable:
				Color.clear
		}
	}
}

private struct WatchProgressFill: View {
	let color: Color
	var start: Date?
	var end: Date?
	let now: Date
	var isBreak = false

	private var progress: Double? {
		guard let start, let end else { return nil }
		let duration = end.timeIntervalSince(start)
		guard duration > 0 else { return 0 }
		return max(0, min(1, now.timeIntervalSince(start) / duration))
	}

	var body: some View {
		GeometryReader { geometry in
			if let progress {
				ZStack(alignment: .leading) {
					if isBreak {
						IrregularGradient(
							colors: [.yellow, .orange, .pink, .red, .purple, .blue, .cyan, .mint, .green],
							background: Color.blue,
							speed: 2,
							animate: true
						)
					}

					UnevenRoundedRectangle(
						cornerRadii: .init(bottomTrailing: 30, topTrailing: 30)
					)
					.fill(isBreak ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(color))
					.frame(width: geometry.size.width * progress)
				}
			} else {
				color
			}
		}
	}
}
