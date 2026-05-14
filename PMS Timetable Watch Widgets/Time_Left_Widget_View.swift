import SwiftUI
import WidgetKit

struct Time_Left_Widget_View: View {
	let entry: TimetableEntry

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: entry.classes)
		let state = getSchoolState(at: entry.date, classLookup: classLookup)

		// Debug: Check if the lookup table even has data
		let _ = print("DEBUG: classLookup count = \(classLookup.count)")

		Group {
			switch state {
				case let .inClass(current, next, info):
					let _ = print("DEBUG: View State -> In Class: \(current?.id ?? "NIL")")
					createProgressView(
						title: current?.id ?? "Free Period",
						symbol: current?.symbol ?? "studentdesk",
						color: current?.colour.swiftUIColor ?? .gray,
						nextText: next != nil ? "Next: \(next!.id)" : "Next: Home",
						start: info.start,
						end: info.end
					)

				case let .inBreak(title, next, info):
					let _ = print("DEBUG: View State -> In Break: \(title)")
					createProgressView(
						title: title,
						symbol: title == "Lunch" ? "takeoutbag.and.cup.and.straw.fill" : "cup.and.saucer.fill",
						color: .orange,
						nextText: next != nil ? "Next: \(next!.id)" : "Last Period",
						start: info.start,
						end: info.end
					)

				case .outsideSchool:
					let _ = print("DEBUG: View State -> Outside School")
					VStack(alignment: .leading) {
						Label("School's Out", systemImage: "house.fill").font(.headline).foregroundColor(.indigo)
						Text("No more classes").font(.system(size: 10)).foregroundColor(.secondary)
					}
			}
		}
	}

	private func createProgressView(title: String, symbol: String, color: Color, nextText: String, start: Date, end: Date) -> some View {
		ZStack(alignment: .leading) {
			GeometryReader { geo in
				let total = end.timeIntervalSince(start)
				let elapsed = Date().timeIntervalSince(start)
				let progress = max(0, min(1, elapsed / total))

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
	case inClass(current: Class?, next: Class?, info: (start: Date, end: Date))
	case inBreak(title: String, next: Class?, info: (start: Date, end: Date))
	case outsideSchool
}

private func getSchoolState(at date: Date, classLookup: [Slot: Class]) -> SchoolState {
	let calendar = Calendar.current
	let weekday = calendar.component(.weekday, from: date)
	let dayIndex = (weekday + 5) % 7

	let hour = calendar.component(.hour, from: date)
	let minute = calendar.component(.minute, from: date)
	let nowMins = hour * 60 + minute

	print("--- TIMETABLE DEBUG START ---")
	print("DEBUG: Current Time: \(hour):\(minute) (\(nowMins) mins)")
	print("DEBUG: Weekday: \(weekday), Calculated dayIndex: \(dayIndex)")

	guard dayIndex < 5 else {
		print("DEBUG: Rejected - Weekend")
		return .outsideSchool
	}

	// 1. Check Classes
	for (i, period) in periodTimes.enumerated() {
		let startMins = period.start.hour * 60 + period.start.min
		let endMins = period.end.hour * 60 + period.end.min

		if nowMins >= startMins, nowMins < endMins {
			print("DEBUG: Hit Period Index \(i) (\(startMins)-\(endMins) mins)")

			let slot = Slot(dayIndex, i + 1)
			let current = classLookup[slot]

			if current == nil {
				print("DEBUG: WARNING - Class is NIL at Slot(\(dayIndex), \(i)). This is why you see 'Free Period'.")
			} else {
				print("DEBUG: Found Class: \(current!.id)")
			}

			let next = (i + 1 < periodTimes.count) ? classLookup[Slot(dayIndex, i + 3)] : nil
			let dates = getDates(start: period.start, end: period.end, relativeTo: date)
			return .inClass(current: current, next: next, info: dates)
		}
	}

	// 2. Check Breaks
	for i in 0 ..< (periodTimes.count - 1) {
		let currentEnd = periodTimes[i].end
		let nextStart = periodTimes[i + 1].start
		let bStart = currentEnd.hour * 60 + currentEnd.min
		let bEnd = nextStart.hour * 60 + nextStart.min

		if nowMins >= bStart, nowMins < bEnd {
			print("DEBUG: Hit Break between Period \(i) and \(i + 1)")
			let next = classLookup[Slot(dayIndex, i + 1)]
			let title = (bEnd - bStart > 20) ? "Lunch" : "Recess"
			let dates = getDates(start: currentEnd, end: nextStart, relativeTo: date)
			return .inBreak(title: title, next: next, info: dates)
		}
	}

	print("DEBUG: No period or break matched. Returning OutsideSchool.")
	return .outsideSchool
}

private func getDates(start: (hour: Int, min: Int), end: (hour: Int, min: Int), relativeTo: Date) -> (start: Date, end: Date) {
	let calendar = Calendar.current
	var comps = calendar.dateComponents([.year, .month, .day], from: relativeTo)
	comps.hour = start.hour; comps.minute = start.min
	let s = calendar.date(from: comps) ?? relativeTo
	comps.hour = end.hour; comps.minute = end.min
	let e = calendar.date(from: comps) ?? relativeTo
	return (s, e)
}
