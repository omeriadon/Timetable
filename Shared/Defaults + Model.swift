//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
import Defaults

let appGroupID = "group.com.omeriadon.pms-timetable"

extension Defaults.Serializable {
static var defaults: UserDefaults {
UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
}
}

enum DisplayMode: String, Codable, Equatable {
case symbolsOnly = "symbolsOnly"
case textOnly = "textOnly"
}

extension DisplayMode: Defaults.Serializable {}

extension Defaults.Keys {
static let timetable = Key<[Class]>("timetable", default: defaultTimetable, suite: UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard)
	static let displayMode = Key<DisplayMode>(
		"displayMode",
		default: .textOnly,
		suite: UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
	)
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
