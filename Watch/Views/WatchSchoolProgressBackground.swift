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
			Color.clear
				.glassEffect(
					.clear.tint(.red.opacity(0.8)).interactive(),
					in: WatchCurrentTimeMarkerShape(progress: progress)
				)
				.padding(.horizontal, 10)
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
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
		let circleDiameter: CGFloat = 15
		let lineWidth: CGFloat = 5
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
				x: markerCenterX - lineWidth / 2,
				y: circleDiameter / 2,
				width: lineWidth,
				height: max(0, rect.height - circleDiameter / 2)
			),
			cornerSize: CGSize(width: lineWidth / 2, height: lineWidth / 2)
		)
		return path
	}
}
