//
//  Defaults + Model.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

#if DEBUG
	let appGroupID = "group.omeriadon.pmstimetable"
#else
	let appGroupID = "group.omeriadon-release.pmstimetable"
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
