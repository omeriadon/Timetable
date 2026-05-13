import SwiftUI
import WidgetKit

/// Period schedule: session index -> (start time, end time)
let periodTimes: [(start: (hour: Int, min: Int), end: (hour: Int, min: Int))] = [
	((8, 50), (9, 48)), // Period 1
	((9, 48), (10, 46)), // Period 2
	((11, 8), (12, 6)), // Period 3
	((12, 6), (13, 4)), // Period 4
	((13, 34), (14, 32)), // Period 5
	((14, 32), (15, 30)), // Period 6
]

struct Time_Left_Widget_View: View {
	let classes: [Class]
	@Environment(\.widgetFamily) var family

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)
		let currentSlot = getCurrentSlot()
		let currentClass = currentSlot.flatMap { classLookup[$0] }
		let periodInfo = currentSlot.flatMap { slot in
			periodTimes.indices.contains(slot.session)
				? (session: slot.session, times: periodTimes[slot.session])
				: nil
		}

		if classes.isEmpty {
			VStack(spacing: 4) {
				Text("No timetable")
					.font(.caption2)
			}
		} else if let currentClass, let periodInfo {
			TimelineView(.everyMinute) { context in
				createProgressView(
					currentClass: currentClass,
					periodInfo: periodInfo,
					at: context.date
				)
			}
		} else {
			VStack(spacing: 4) {
				Text("Outside class time")
					.font(.caption2)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}

	@ViewBuilder
	private func createProgressView(
		currentClass: Class,
		periodInfo: (session: Int, times: (start: (hour: Int, min: Int), end: (hour: Int, min: Int))),
		at currentTime: Date
	) -> some View {
		let (secondsRemaining, totalSeconds) = calculateTimeRemaining(
			for: periodInfo.times,
			at: currentTime
		)
		let progress = totalSeconds > 0 ? Double(secondsRemaining) / Double(totalSeconds) : 0

		VStack(spacing: 6) {
			// Header with symbol and class name
			HStack(spacing: 4) {
				Image(systemName: currentClass.symbol)
					.font(.body)
					.frame(width: 20)

				Text(currentClass.id)
					.font(.caption2)
					.lineLimit(1)

				Spacer()
			}

			// Time remaining in seconds
			Text("\(secondsRemaining)s")
				.font(.caption)
				.monospacedDigit()
				.lineLimit(1)

			// Progress gauge rectangle
			GeometryReader { geo in
				ZStack(alignment: .leading) {
					// Background track
					RoundedRectangle(cornerRadius: 3)
						.fill(Color.gray.opacity(0.3))

					// Progress fill
					RoundedRectangle(cornerRadius: 3)
						.fill(currentClass.colour.swiftUIColor)
						.frame(width: geo.size.width * progress)
				}
			}
			.frame(height: 8)
		}
		.padding(6)
		.animation(.linear, value: secondsRemaining)
	}

	private func getCurrentSlot() -> Slot? {
		let today = Date()
		let weekday = Calendar.current.component(.weekday, from: today)
		let dayIndex = (weekday + 5) % 7 // Convert to 0 = Monday

		// Skip weekends (Saturday = 5, Sunday = 6)
		guard dayIndex < 5 else { return nil }

		let hour = Calendar.current.component(.hour, from: today)
		let minute = Calendar.current.component(.minute, from: today)
		let timeInMinutes = hour * 60 + minute

		// Determine which period we're in
		for (sessionIndex, (start, end)) in periodTimes.enumerated() {
			let startMinutes = start.hour * 60 + start.min
			let endMinutes = end.hour * 60 + end.min
			if timeInMinutes >= startMinutes, timeInMinutes < endMinutes {
				return Slot(dayIndex, sessionIndex)
			}
		}
		return nil
	}

	private func calculateTimeRemaining(
		for times: (start: (hour: Int, min: Int), end: (hour: Int, min: Int)),
		at currentTime: Date
	) -> (remaining: Int, total: Int) {
		let hour = Calendar.current.component(.hour, from: currentTime)
		let minute = Calendar.current.component(.minute, from: currentTime)
		let second = Calendar.current.component(.second, from: currentTime)
		let currentSeconds = hour * 3600 + minute * 60 + second

		let endSeconds = times.end.hour * 3600 + times.end.min * 60
		let startSeconds = times.start.hour * 3600 + times.start.min * 60

		let remaining = max(0, endSeconds - currentSeconds)
		let total = endSeconds - startSeconds

		return (remaining, total)
	}
}
