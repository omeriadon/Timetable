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

	var minutes: Int {
		rawValue
	}
}

nonisolated struct AccountSettings: Codable, Defaults.Serializable, Hashable {
	var liveActivitiesEnabled: Bool
	var notificationsEnabled: Bool
	var notificationLeadTime: NotificationLeadTime

	static let `default` = AccountSettings(
		liveActivitiesEnabled: true,
		notificationsEnabled: false,
		notificationLeadTime: .zero
	)

	init(liveActivitiesEnabled: Bool, notificationsEnabled: Bool, notificationLeadTime: NotificationLeadTime) {
		self.liveActivitiesEnabled = liveActivitiesEnabled
		self.notificationsEnabled = notificationsEnabled
		self.notificationLeadTime = notificationLeadTime
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		liveActivitiesEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivitiesEnabled) ?? Self.default.liveActivitiesEnabled
		notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? Self.default.notificationsEnabled
		notificationLeadTime = try container.decodeIfPresent(NotificationLeadTime.self, forKey: .notificationLeadTime) ?? .zero
	}
}
