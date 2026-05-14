import SwiftUI
import WidgetKit

struct Time_Left_Widget_View: View {
	let entry: TimetableEntry // CRITICAL: Use the entry date
	@Environment(\.widgetFamily) var family

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: entry.classes)

		// Fix: Use entry.date, NOT Date()
		let state = getSchoolState(at: entry.date, classLookup: classLookup)

		Group {
			switch state {
				case let .inClass(current, next, info):
					createProgressView(
						title: current.id,
						symbol: current.symbol,
						color: current.colour.swiftUIColor,
						nextText: next != nil ? "Next: \(next!.id)" : "Last Period",
						start: info.start,
						end: info.end
					)

				case let .inBreak(title, next, info):
					createProgressView(
						title: title,
						symbol: "cup.and.saucer.fill",
						color: .gray,
						nextText: "Next: \(next.id)",
						start: info.start,
						end: info.end
					)

				case .outsideSchool:
					VStack(spacing: 4) {
						Text("Outside class time")
							.font(.system(size: 12, weight: .medium))
							.opacity(0.8)
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
	}

	/// A unified view that handles both classes and breaks
	private func createProgressView(
		title: String,
		symbol: String,
		color: Color,
		nextText: String,
		start: Date,
		end: Date
	) -> some View {
		ZStack(alignment: .leading) {
			ProgressView(timerInterval: start ... end, countsDown: false)
				.progressViewStyle(.linear)
				.tint(color)
				.scaleEffect(x: 1, y: 4, anchor: .center)
				.opacity(0.5)

			HStack {
				VStack(alignment: .leading) {
					Label(title, systemImage: symbol)
						.font(.headline)
						.widgetAccentable()

					Text("\(end, style: .timer) left")
						.monospacedDigit()
						.font(.footnote)

					Spacer(minLength: 1)

					Text(nextText)
						.font(.system(size: 10))
						.lineLimit(1)
				}
				Spacer(minLength: 0)
			}
			.padding(.leading, 7)
			.padding(.vertical, 4)
		}
		.ignoresSafeArea()
	}

	private func getStartAndEndDates(
		for info: (session: Int, times: (start: (hour: Int, min: Int), end: (hour: Int, min: Int))),
		at now: Date
	) -> (start: Date, end: Date) {
		let calendar = Calendar.current
		var components = calendar.dateComponents([.year, .month, .day], from: now)

		components.hour = info.times.start.hour
		components.minute = info.times.start.min
		let start = calendar.date(from: components) ?? now

		components.hour = info.times.end.hour
		components.minute = info.times.end.min
		let end = calendar.date(from: components) ?? now

		return (start, end)
	}

	private func calculateProgress(start: (hour: Int, min: Int), end: (hour: Int, min: Int), now: Date) -> Double {
		let calendar = Calendar.current

		// Create Date objects for the start and end of this specific period
		var components = calendar.dateComponents([.year, .month, .day], from: now)

		components.hour = start.hour
		components.minute = start.min
		let startDate = calendar.date(from: components) ?? now

		components.hour = end.hour
		components.minute = end.min
		let endDate = calendar.date(from: components) ?? now

		let totalDuration = endDate.timeIntervalSince(startDate)
		let elapsed = now.timeIntervalSince(startDate)

		// Return a clamped value between 0.0 and 1.0
		guard totalDuration > 0 else { return 0 }
		return max(0, min(1, elapsed / totalDuration))
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

enum SchoolState {
	case inClass(current: Class, next: Class?, info: (start: Date, end: Date))
	case inBreak(title: String, next: Class, info: (start: Date, end: Date))
	case outsideSchool
}

private func getSchoolState(at date: Date, classLookup: [Slot: Class]) -> SchoolState {
	let calendar = Calendar.current
	let weekday = calendar.component(.weekday, from: date)
	let dayIndex = (weekday + 5) % 7
	guard dayIndex < 5 else { return .outsideSchool }

	let hour = calendar.component(.hour, from: date)
	let minute = calendar.component(.minute, from: date)
	let nowTotalMinutes = hour * 60 + minute

	// Check Periods
	for (i, period) in periodTimes.enumerated() {
		let startMins = period.start.hour * 60 + period.start.min
		let endMins = period.end.hour * 60 + period.end.min

		if nowTotalMinutes >= startMins, nowTotalMinutes < endMins {
			if let current = classLookup[Slot(dayIndex, i)] {
				let next = classLookup[Slot(dayIndex, i + 1)]
				let dates = getDates(start: period.start, end: period.end, relativeTo: date)
				return .inClass(current: current, next: next, info: dates)
			}
		}
	}

	// Check if we are BETWEEN periods (Breaks)
	for i in 0 ..< (periodTimes.count - 1) {
		let currentPeriodEnd = periodTimes[i].end
		let nextPeriodStart = periodTimes[i + 1].start

		let breakStartMins = currentPeriodEnd.hour * 60 + currentPeriodEnd.min
		let breakEndMins = nextPeriodStart.hour * 60 + nextPeriodStart.min

		if nowTotalMinutes >= breakStartMins, nowTotalMinutes < breakEndMins {
			if let nextClass = classLookup[Slot(dayIndex, i + 1)] {
				let title = (breakEndMins - breakStartMins > 20) ? "Lunch" : "Recess"
				let dates = getDates(start: currentPeriodEnd, end: nextPeriodStart, relativeTo: date)
				return .inBreak(title: title, next: nextClass, info: dates)
			}
		}
	}

	return .outsideSchool
}

private func getDates(start: (hour: Int, min: Int), end: (hour: Int, min: Int), relativeTo: Date) -> (start: Date, end: Date) {
	let calendar = Calendar.current
	var comps = calendar.dateComponents([.year, .month, .day], from: relativeTo)
	comps.hour = start.hour; comps.minute = start.min
	let s = calendar.date(from: comps)!
	comps.hour = end.hour; comps.minute = end.min
	let e = calendar.date(from: comps)!
	return (s, e)
}
