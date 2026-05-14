import SwiftUI
import WidgetKit

struct Time_Left_Widget_View: View {
	let entry: TimetableEntry

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: entry.classes)
		let state = getSchoolState(at: entry.date, classLookup: classLookup)

		Group {
			switch state {
				case let .inClass(current, nextText, info):
					createProgressView(
						title: current?.id ?? "Free Period",
						symbol: current?.symbol ?? "studentdesk",
						color: current?.colour.swiftUIColor ?? .gray,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case let .inBreak(title, nextText, info):
					createProgressView(
						title: title,
						symbol: title == "Lunch" ? "takeoutbag.and.cup.and.straw.fill" : "cup.and.saucer.fill",
						color: .orange,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case .outsideSchool:
					VStack(alignment: .leading) {
						Label("School's Out", systemImage: "house.fill")
							.font(.headline)
							.foregroundColor(.indigo)

						Text("No more classes")
							.font(.system(size: 10))
							.foregroundColor(.secondary)
					}
			}
		}
	}

	private func createProgressView(
		title: String,
		symbol: String,
		color: Color,
		nextText: String,
		start: Date,
		end: Date
	) -> some View {
		ZStack(alignment: .leading) {
			GeometryReader { geo in
				let total = end.timeIntervalSince(start)
				let elapsed = Date().timeIntervalSince(start)
				let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0

				VStack {
					Rectangle()
						.fill(color)
						.frame(width: geo.size.width * progress)

					Spacer(minLength: 0)
				}
			}
			.tint(color)
			.widgetAccentable()

			VStack(alignment: .leading) {
				Label(title, systemImage: symbol)
					.font(.headline)
					.lineLimit(1)

				Spacer(minLength: 1)

				Text(end, style: .timer)
					.font(.system(.body, design: .monospaced))

				Spacer(minLength: 1)

				Text(nextText)
					.font(.body.scaled(by: 0.9))
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
			.padding([.vertical, .leading])
		}
	}
}

enum SchoolState {
	case inClass(current: Class?, nextText: String, info: (start: Date, end: Date))
	case inBreak(title: String, nextText: String, info: (start: Date, end: Date))
	case outsideSchool
}

private func getSchoolState(at date: Date, classLookup: [Slot: Class]) -> SchoolState {
	let calendar = Calendar.current
	let weekday = calendar.component(.weekday, from: date)
	let dayIndex = (weekday + 5) % 7

	guard dayIndex < 5 else {
		return .outsideSchool
	}

	let nowMins = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)

	for (index, period) in periodTimes.enumerated() {
		let startMins = minutes(period.start)
		let endMins = minutes(period.end)

		if nowMins >= startMins, nowMins < endMins {
			let current = classForPeriod(index, dayIndex: dayIndex, classLookup: classLookup)
			let nextText = nextTextAfterClass(periodIndex: index, dayIndex: dayIndex, classLookup: classLookup)
			let dates = getDates(start: period.start, end: period.end, relativeTo: date)
			return .inClass(current: current, nextText: nextText, info: dates)
		}

		if index < periodTimes.count - 1 {
			let nextPeriod = periodTimes[index + 1]
			let breakStart = period.end
			let breakEnd = nextPeriod.start
			let breakStartMins = minutes(breakStart)
			let breakEndMins = minutes(breakEnd)

			if nowMins >= breakStartMins, nowMins < breakEndMins {
				let title = (breakEndMins - breakStartMins > 20) ? "Lunch" : "Recess"
				let nextClass = classForPeriod(index + 1, dayIndex: dayIndex, classLookup: classLookup)
				let nextText = "Next: \(nextClass?.id ?? "Free Period")"
				let dates = getDates(start: breakStart, end: breakEnd, relativeTo: date)
				return .inBreak(title: title, nextText: nextText, info: dates)
			}
		}
	}

	return .outsideSchool
}

private func classForPeriod(_ periodIndex: Int, dayIndex: Int, classLookup: [Slot: Class]) -> Class? {
	let periodNumber = periodIndex + 1
	guard let session = TimetableLayout.session(forPeriod: periodNumber) else {
		return nil
	}

	return classLookup[Slot(dayIndex, session)]
}

private func nextTextAfterClass(periodIndex: Int, dayIndex: Int, classLookup: [Slot: Class]) -> String {
	guard periodIndex < periodTimes.count - 1 else {
		return "Last Period"
	}

	let currentEnd = minutes(periodTimes[periodIndex].end)
	let nextStart = minutes(periodTimes[periodIndex + 1].start)
	let gap = nextStart - currentEnd

	if gap > 0 {
		return "Next: \(gap > 20 ? "Lunch" : "Recess")"
	}

	let nextClass = classForPeriod(periodIndex + 1, dayIndex: dayIndex, classLookup: classLookup)
	return "Next: \(nextClass?.id ?? "Free Period")"
}

private func minutes(_ time: (hour: Int, min: Int)) -> Int {
	time.hour * 60 + time.min
}

private func getDates(
	start: (hour: Int, min: Int),
	end: (hour: Int, min: Int),
	relativeTo: Date
) -> (start: Date, end: Date) {
	let calendar = Calendar.current
	var comps = calendar.dateComponents([.year, .month, .day], from: relativeTo)

	comps.hour = start.hour
	comps.minute = start.min
	let s = calendar.date(from: comps) ?? relativeTo

	comps.hour = end.hour
	comps.minute = end.min
	let e = calendar.date(from: comps) ?? relativeTo

	return (s, e)
}

#Preview {
	Time_Left_Widget_View(
		entry: TimetableEntry(
			date: Date(),
			classes: defaultTimetable,
			displayMode: .textOnly,
			relevance: TimelineEntryRelevance(score: 1, duration: 60 * 60)
		)
	)
}
