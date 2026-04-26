//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI

enum DisplayMode: String, Codable, Equatable {
	case symbolsOnly = "symbolsOnly"
	case textOnly = "textOnly"
}

#if !os(watchOS)
import Defaults

extension DisplayMode: Defaults.Serializable {}

extension Defaults.Keys {
	static let timetable = Key<[Class]>("timetable", default: defaultTimetable)
	static let displayMode = Key<DisplayMode>("displayMode", default: .symbolsOnly)
}
#endif

// array of class
// class = name + what slots + colour + symbol

#if os(watchOS)
struct Class: Hashable, Codable, Identifiable {
	var id: String
	var symbol: String
	var colour: RGBAColor
	var slots: [Slot]
}

struct Slot: Hashable, Codable {
	let day: Int
	let session: Int

	init(_ day: Int, _ session: Int) {
		self.day = day
		self.session = session
	}
}
#else
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
#endif
