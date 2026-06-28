//
//   AccountSettings.swift
//   Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation

struct TimeOfDay: Codable, Defaults.Serializable, Hashable {
	let hour: Int
	let minute: Int

	init(_ hour: Int, _ minute: Int) {
		self.hour = hour
		self.minute = minute
	}
}

enum SchoolWeekday: String, Codable, Defaults.Serializable, Hashable {
	case monday
	case tuesday
	case wednesday
	case thursday
	case friday
	case saturday
	case sunday
}

struct AccountSettings: Codable, Defaults.Serializable, Hashable {
	var liveActivitiesEnabled: Bool
	var liveActivityStartTime: TimeOfDay
	var liveActivityEndTime: TimeOfDay
	var liveActivityWeekdays: Set<SchoolWeekday>
	var showBreaksInLiveActivity: Bool
	var showNextSubjectInLiveActivity: Bool
	var widgetShowsReceivedTimetables: Bool
	var spotlightIndexingEnabled: Bool
	var siriAccessEnabled: Bool

	static let `default` = AccountSettings(
		liveActivitiesEnabled: true,
		liveActivityStartTime: TimeOfDay(8, 0),
		liveActivityEndTime: TimeOfDay(15, 40),
		liveActivityWeekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
		showBreaksInLiveActivity: true,
		showNextSubjectInLiveActivity: true,
		widgetShowsReceivedTimetables: true,
		spotlightIndexingEnabled: true,
		siriAccessEnabled: true
	)
}
