//
//   AccountSettings.swift
//   Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation

nonisolated enum NotificationLeadTime: Int, Codable, CaseIterable, Defaults.Serializable, Hashable {
	case zero = 0
	case one = 1
	case two = 2
	case three = 3
	case four = 4
	case five = 5
	case ten = 10

	var minutes: Int {
		rawValue
	}
}

nonisolated struct AccountSettings: Codable, Defaults.Serializable, Hashable {
	var liveActivitiesEnabled: Bool
	var highlightsCurrentDay: Bool
	var notificationsEnabled: Bool
	var broadcastNotificationsEnabled: Bool
	var notificationLeadTimes: Set<NotificationLeadTime>

	private enum LegacyCodingKeys: String, CodingKey {
		case notificationLeadTime
	}

	static let `default` = AccountSettings(
		liveActivitiesEnabled: true,
		highlightsCurrentDay: true,
		notificationsEnabled: true,
		broadcastNotificationsEnabled: true,
		notificationLeadTimes: [.zero]
	)

	init(liveActivitiesEnabled: Bool, highlightsCurrentDay: Bool = true, notificationsEnabled: Bool, broadcastNotificationsEnabled: Bool, notificationLeadTimes: Set<NotificationLeadTime>) {
		self.liveActivitiesEnabled = liveActivitiesEnabled
		self.highlightsCurrentDay = highlightsCurrentDay
		self.notificationsEnabled = notificationsEnabled
		self.broadcastNotificationsEnabled = broadcastNotificationsEnabled
		self.notificationLeadTimes = notificationLeadTimes
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
		liveActivitiesEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivitiesEnabled) ?? Self.default.liveActivitiesEnabled
		highlightsCurrentDay = try container.decodeIfPresent(Bool.self, forKey: .highlightsCurrentDay) ?? Self.default.highlightsCurrentDay
		notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? Self.default.notificationsEnabled
		broadcastNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .broadcastNotificationsEnabled) ?? Self.default.broadcastNotificationsEnabled
		if let leadTimes = try container.decodeIfPresent(Set<NotificationLeadTime>.self, forKey: .notificationLeadTimes) {
			notificationLeadTimes = leadTimes
		} else if let legacyLeadTime = try legacyContainer.decodeIfPresent(NotificationLeadTime.self, forKey: .notificationLeadTime) {
			notificationLeadTimes = [legacyLeadTime]
		} else {
			notificationLeadTimes = Self.default.notificationLeadTimes
		}
	}
}
