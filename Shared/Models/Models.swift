//
//   Models.swift
//   Shared
//
//   Created by Adon Omeri on 25/4/2026.
//

import AppIntents
import Defaults
import SwiftUI

enum DisplayMode: String, Codable, Equatable, Defaults.Serializable {
	case symbolsOnly
	case textOnly
}

nonisolated struct Slot: Hashable, Codable, Defaults.Serializable {
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

struct EditableSubject: Identifiable {
	let id = UUID()
	var originalName: String?
	var name: String
	var symbol: String
	var color: Color
	var slots: [EditableSlot]
	var classroom: String
	var teacher: String
}

nonisolated enum TimetableLayout {
	static let sessions = ["1", "2", "R", "3", "4", "L", "5", "6"]
	static let shortDayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri"]
	static let fullDayLabels = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
	static let teachingSessionIndices = [0, 1, 3, 4, 6, 7]
	#if os(watchOS)
		static let sessionCellHeight: CGFloat = 25
		static let breakCellHeight: CGFloat = 2
	#else
		static let sessionCellHeight: CGFloat = 60
		static let breakCellHeight: CGFloat = 20
	#endif

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

	static func subjectLookup(for subjects: [Subject]) -> [Slot: Subject] {
		var lookup: [Slot: Subject] = [:]

		for subjectItem in subjects {
			for slot in subjectItem.slots {
				lookup[slot] = subjectItem
			}
		}

		return lookup
	}
}
