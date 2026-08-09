import SwiftUI

struct WatchCurrentTimeMarker: View {
	let state: SchoolState
	let now: Date

	private var interval: DateInterval? {
		switch state {
			case let .lesson(lesson):
				DateInterval(start: lesson.interval.start, end: lesson.interval.end)
			case let .freePeriod(period):
				DateInterval(start: period.interval.start, end: period.interval.end)
			case let .recess(breakState), let .lunch(breakState):
				DateInterval(start: breakState.interval.start, end: breakState.interval.end)
			case .beforeSchool, .afterSchool, .weekend, .noTimetable:
				nil
		}
	}

	private var progress: CGFloat? {
		guard let interval, interval.duration > 0 else { return nil }
		return CGFloat(max(0, min(1, now.timeIntervalSince(interval.start) / interval.duration)))
	}

	var body: some View {
		if let progress {
			GeometryReader { geometry in
				let markerDiameter: CGFloat = 12
				let markerX = max(
					0,
					min(geometry.size.width - markerDiameter, geometry.size.width * progress - markerDiameter / 2)
				)

				ZStack(alignment: .topLeading) {
					Capsule()
						.fill(.red)
						.frame(maxWidth: .infinity)
						.frame(height: 3)
						.padding(.top, markerDiameter / 2 - 1.5)

					Rectangle()
						.fill(.red)
						.frame(width: 3, height: 12)
						.offset(x: markerX + markerDiameter / 2 - 1.5, y: markerDiameter - 1)

					Circle()
						.fill(.red)
						.frame(width: markerDiameter, height: markerDiameter)
						.offset(x: markerX)
				}
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 8)
			.frame(height: 28)
			.accessibilityLabel("Current time")
		} else {
			Color.clear
				.frame(height: 0)
		}
	}
}
