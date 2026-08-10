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
				let circleDiameter: CGFloat = 15
				let markerX = max(
					0,
					min(
						geometry.size.width - circleDiameter,
						geometry.size.width * progress - circleDiameter / 2
					)
				)

				Color.clear
					.background(.red.gradient.opacity(0.9), in: WatchCurrentTimeMarkerShape())
					.overlay {
						WatchCurrentTimeMarkerShape()
							.stroke(.red, lineWidth: 0.4)
					}
					.shadow(color: .red.mix(with: .black, by: 0.5), radius: 4)
					.frame(width: circleDiameter, height: geometry.size.height)
					.offset(x: markerX)
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 6)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.accessibilityLabel("Current time")
		} else {
			Color.clear
				.frame(height: 0)
		}
	}
}

private struct WatchCurrentTimeMarkerShape: Shape {
	func path(in rect: CGRect) -> Path {
		let circleDiameter: CGFloat = 15
		let lineWidth: CGFloat = 5
		let markerCenterX = circleDiameter / 2
		let radius = lineWidth / 2

		let circle = Path(
			ellipseIn: CGRect(
				x: 0,
				y: 0,
				width: circleDiameter,
				height: circleDiameter
			)
		)

		var stem = Path()

		// Straight stem, extending underneath the circle.
		stem.addRect(
			CGRect(
				x: markerCenterX - radius,
				y: circleDiameter / 2,
				width: lineWidth,
				height: max(0, rect.height - circleDiameter / 2 - radius)
			)
		)

		// Only round the bottom.
		stem.addEllipse(
			in: CGRect(
				x: markerCenterX - radius,
				y: rect.height - lineWidth,
				width: lineWidth,
				height: lineWidth
			)
		)

		return circle.union(stem)
	}
}
