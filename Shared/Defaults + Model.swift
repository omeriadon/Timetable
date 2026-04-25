//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
import Defaults

extension Defaults.Keys {
	static let timetable = Key<[Class]>("timetable", default: defaultTimetable)
}

// array of class
// class = name + what slots + colour + symbol

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
