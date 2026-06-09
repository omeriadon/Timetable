//
//  Defaults + Model.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

private let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? UserDefaults.standard

extension Defaults.Serializable {
	static var defaults: UserDefaults {
		sharedDefaults
	}
}

enum DisplayMode: String, Codable, Equatable {
	case symbolsOnly
	case textOnly
}

extension DisplayMode: Defaults.Serializable {}

struct ReceivedTimetable: Codable, Defaults.Serializable, Identifiable {
	var id: String {
		sender
	}

	let sender: String
	let classes: [Class]
	let receivedAt: Date
}

extension Defaults.Keys {
	static let timetable = Key<[Class]>("timetable", default: defaultTimetable, suite: sharedDefaults)
	static let displayMode = Key<DisplayMode>("displayMode", default: .textOnly, suite: sharedDefaults)
	static let receivedTimetables = Key<[ReceivedTimetable]>("receivedTimetables", default: [], suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "My Timetable", suite: sharedDefaults)
}

struct Class: Hashable, Codable, Defaults.Serializable, Identifiable {
	var id: String
	var symbol: String
	var colour: RGBAColor
	var slots: [Slot]
}

struct Slot: Hashable, Codable, Defaults.Serializable {
	let day: Int
	let session: Int

	init(_ day: Int, _ session: Int) {
		self.day = day
		self.session = session
	}
}

struct EditableSlot: Identifiable, Hashable {
	let id = UUID()
	var day: Int
	var period: Int
}

struct EditableClass: Identifiable {
	let id = UUID()
	var originalName: String?
	var name: String
	var symbol: String
	var color: Color
	var slots: [EditableSlot]
}

enum TimetableLayout {
	static let sessions = ["1", "2", "R", "3", "4", "L", "5", "6"]
	static let shortDayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri"]
	static let fullDayLabels = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
	static let teachingSessionIndices = [0, 1, 3, 4, 6, 7]

	static func isBreakSession(index: Int) -> Bool {
		index == 2 || index == 5
	}

	static func isBreakSession(label: String) -> Bool {
		label == "R" || label == "L"
	}

	static func isUnavailable(day: Int, session: Int) -> Bool {
		(day == 2 && session == 7) || (day == 4 && session == 7)
	}

	static func allowedPeriods(for day: Int) -> [Int] {
		(day == 2 || day == 4) ? Array(1 ... 5) : Array(1 ... 6)
	}

	static func canUse(period: Int, on day: Int) -> Bool {
		!(period == 6 && (day == 2 || day == 4))
	}

	static func session(forPeriod period: Int) -> Int? {
		switch period {
			case 1: 0
			case 2: 1
			case 3: 3
			case 4: 4
			case 5: 6
			case 6: 7
			default: nil
		}
	}

	static func period(forSession session: Int) -> Int? {
		switch session {
			case 0: 1
			case 1: 2
			case 3: 3
			case 4: 4
			case 6: 5
			case 7: 6
			default: nil
		}
	}

	static func classLookup(for classes: [Class]) -> [Slot: Class] {
		var lookup: [Slot: Class] = [:]

		for classItem in classes {
			for slot in classItem.slots {
				lookup[slot] = classItem
			}
		}

		return lookup
	}
}
