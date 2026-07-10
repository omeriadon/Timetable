import SwiftUI
import WidgetKit

struct NextBreakView: View {
	let entry: NextBreakEntry

	@Environment(\.widgetFamily) private var family

	var body: some View {
		Group {
			#if os(iOS) || os(watchOS)
				if family == .accessoryRectangular {
					accessoryContent
				} else {
					homeScreenContent
				}
			#else
				homeScreenContent
			#endif
		}
		.dynamicTypeSize(.medium)
	}

	private var homeScreenContent: some View {
		VStack(alignment: .leading, spacing: 8) {
			Image(systemName: entry.breakType?.symbol ?? "house.fill")
				.font(.title2)
				.foregroundStyle(.orange)

			Spacer()

			Text(entry.breakType?.description ?? "School's Out")
				.font(.headline)
				.lineLimit(1)

			if let interval = entry.interval {
				Text(timerInterval: TimetableClock.adjusted(entry.date) ... interval.start, countsDown: true)
					.font(.title2.monospacedDigit())
					.contentTransition(.numericText(countsDown: true))
				Text("until it starts")
					.font(.caption)
					.foregroundStyle(.secondary)
			} else {
				Text("No more breaks today")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
	}

	private var accessoryContent: some View {
		HStack(spacing: 8) {
			Image(systemName: entry.breakType?.symbol ?? "house.fill")
			VStack(alignment: .leading, spacing: 1) {
				Text(entry.breakType?.description ?? "No More Breaks")
					.font(.headline)
				if let interval = entry.interval {
					Text(timerInterval: TimetableClock.adjusted(entry.date) ... interval.start, countsDown: true)
						.font(.caption.monospacedDigit())
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}
