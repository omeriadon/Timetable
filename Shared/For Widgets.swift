//
//  For Widgets.swift
//  Timetable
//
//  Created by Adon Omeri on 11/6/2026.
//

import Foundation

let periodTimes: [(start: (hour: Int, min: Int), end: (hour: Int, min: Int))] = [
	((8, 50), (9, 48)), // Period 1
	((9, 48), (10, 46)), // Period 2
	((11, 8), (12, 6)), // Period 3
	((12, 6), (13, 4)), // Period 4
	((13, 34), (14, 32)), // Period 5
	((14, 32), (15, 30)), // Period 6
]

let schoolStartHour = 8
let schoolStartMinute = 30
let schoolEndHour = 15
let schoolEndMinute = 30
let tickMinutes = 8

enum SchoolState {
	case beforeSchool(next: Class)
	case inClass(current: Class?, nextText: String, info: (start: Date, end: Date))
	case inBreak(breakType: BreakType, nextText: String, info: (start: Date, end: Date))
	case outsideSchool
}

enum BreakType {
	case recess
	case lunch
}

func getSchoolState(at date: Date, classLookup: [Slot: Class]) -> SchoolState {
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
				let recess = (breakStart.hour == 10 && breakStart.min == 46)
				let breakType: BreakType = recess ? .recess : .lunch

				let nextClass = classForPeriod(index + 1, dayIndex: dayIndex, classLookup: classLookup)
				let nextText = "Next: \(nextClass?.id ?? "Free Period")"
				let dates = getDates(start: breakStart, end: breakEnd, relativeTo: date)

				return .inBreak(breakType: breakType, nextText: nextText, info: dates)
			}
		}
	}

	return .outsideSchool
}

func classForPeriod(_ periodIndex: Int, dayIndex: Int, classLookup: [Slot: Class]) -> Class? {
	let periodNumber = periodIndex + 1
	guard let session = TimetableLayout.session(forPeriod: periodNumber) else {
		return nil
	}

	return classLookup[Slot(dayIndex, session)]
}

func nextTextAfterClass(periodIndex: Int, dayIndex: Int, classLookup: [Slot: Class]) -> String {
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

func minutes(_ time: (hour: Int, min: Int)) -> Int {
	time.hour * 60 + time.min
}

func getDates(
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
