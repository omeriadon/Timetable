//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
import Defaults

extension Defaults.Keys {
	static let timetable = Key<Set<Class>>("timetable", default: [])
}

// array of class
// class = name + what slots + colour + symbol

struct Class: Hashable, Codable, Defaults.Serializable, Identifiable {

	var id: String

	var symbol: String

	var colour: Color.Resolved

	var slots: Set<Slot>
}

struct Slot: Hashable, Codable {
	let day: Int
	let session: Int

	init(_ day: Int, _ session: Int) {
		self.day = day
		self.session = session
	}
}
