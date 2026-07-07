import IrregularGradient
import SwiftUI

struct WatchSchoolProgressBackground: View {
	let state: SchoolState
	let now: Date

	var body: some View {
		switch state {
			case let .beforeSchool(next):
				WatchProgressFill(color: next.colour.swiftUIColor, now: now)
			case let .inClass(current, _, info):
				WatchProgressFill(
					color: current?.colour.swiftUIColor ?? .blue,
					start: info.start,
					end: info.end,
					now: now
				)
			case let .inBreak(_, _, info):
				WatchProgressFill(
					color: .black,
					start: info.start,
					end: info.end,
					now: now,
					isBreak: true
				)
			case .outsideSchool:
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
