//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

#if os(watchOS)
let appGroupID = "group.omeriadon.pmstimetable"
#elseif DEBUG
let appGroupID = "group.omeriadon.debug.pmstimetable"
#else
let appGroupID = "group.omeriadon.pmstimetable"
#endif

private let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard

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

extension Defaults.Keys {
	static let timetable = Key<[Class]>("timetable", default: defaultTimetable, suite: sharedDefaults)
	static let displayMode = Key<DisplayMode>("displayMode", default: .textOnly, suite: sharedDefaults)
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
