//
//  Defaults.swift
//  Timetable
//
//  Created by Adon Omeri on 12/6/2026.
//

import Defaults
import Foundation

private let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? UserDefaults.standard

extension Defaults.Keys {
	static let timetable = Key<[Class]>("timetable", default: defaultTimetable, suite: sharedDefaults)
	static let receivedTimetables = Key<[ReceivedTimetable]>("receivedTimetables", default: [], suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "My Timetable", suite: sharedDefaults)
}
