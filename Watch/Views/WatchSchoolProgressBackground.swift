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
			GeometryReader { _ in
				Color.clear
					.glassEffect(
						.regular.tint(.red),
						in: WatchCurrentTimeMarkerShape(progress: progress)
					)
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 8)
			.frame(height: 32)
			.layoutPriority(1)
			.accessibilityLabel("Current time")
		} else {
			Color.clear
				.frame(height: 0)
		}
	}
}

private struct WatchCurrentTimeMarkerShape: Shape {
	var progress: CGFloat

	func path(in rect: CGRect) -> Path {
		let circleDiameter: CGFloat = 12
		let lineHeight: CGFloat = 5
		let markerX = max(
			0,
			min(rect.width - circleDiameter, rect.width * progress - circleDiameter / 2)
		)
		let markerCenterX = markerX + circleDiameter / 2

		var path = Path()
		path.addEllipse(
			in: CGRect(
				x: markerX,
				y: 0,
				width: circleDiameter,
				height: circleDiameter
			)
		)
		path.addRoundedRect(
			in: CGRect(
				x: markerCenterX - 1.5,
				y: circleDiameter - 1,
				width: 3,
				height: rect.height - circleDiameter + 1
			),
			cornerSize: CGSize(width: 1.5, height: 1.5)
		)
		path.addRoundedRect(
			in: CGRect(
				x: 0,
				y: circleDiameter / 2 - lineHeight / 2,
				width: rect.width,
				height: lineHeight
			),
			cornerSize: CGSize(width: lineHeight / 2, height: lineHeight / 2)
		)
		return path
	}
}
