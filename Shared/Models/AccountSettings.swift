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
	var appFontDesign: AppFontDesign
	var appBackground: AppBackground
	var futureEventRange: FutureEventRange
	var watchBleedEnabled: Bool
	var notificationsEnabled: Bool
	var broadcastNotificationsEnabled: Bool
	var notificationLeadTimes: Set<NotificationLeadTime>
	var breakToPeriodNotificationLeadTimes: Set<NotificationLeadTime>
	var eventNotificationSchedules: Set<EventNotificationSchedule>
	var calendarEventAutoDeleteDays: Int
	var serverRevision: Int

	private enum LegacyCodingKeys: String, CodingKey {
		case notificationLeadTime
	}

	static let `default` = AccountSettings(
		liveActivitiesEnabled: true,
		appFontDesign: .monospaced,
		appBackground: .paper,
		futureEventRange: .oneMonth,
		watchBleedEnabled: true,
		notificationsEnabled: true,
		broadcastNotificationsEnabled: true,
		notificationLeadTimes: [.zero],
		breakToPeriodNotificationLeadTimes: [.zero],
		eventNotificationSchedules: [],
		calendarEventAutoDeleteDays: 0,
		serverRevision: 0
	)

	init(
		liveActivitiesEnabled: Bool,
		appFontDesign: AppFontDesign = .monospaced,
		appBackground: AppBackground = .paper,
		futureEventRange: FutureEventRange = .oneMonth,
		watchBleedEnabled: Bool = true,
		notificationsEnabled: Bool,
		broadcastNotificationsEnabled: Bool,
		notificationLeadTimes: Set<NotificationLeadTime>,
		breakToPeriodNotificationLeadTimes: Set<NotificationLeadTime> = [.zero],
		eventNotificationSchedules: Set<EventNotificationSchedule> = [],
		calendarEventAutoDeleteDays: Int = 0,
		serverRevision: Int = 0
	) {
		self.liveActivitiesEnabled = liveActivitiesEnabled
		self.appFontDesign = appFontDesign
		self.appBackground = appBackground
		self.futureEventRange = futureEventRange
		self.watchBleedEnabled = watchBleedEnabled
		self.notificationsEnabled = notificationsEnabled
		self.broadcastNotificationsEnabled = broadcastNotificationsEnabled
		self.notificationLeadTimes = notificationLeadTimes
		self.breakToPeriodNotificationLeadTimes = breakToPeriodNotificationLeadTimes
		self.eventNotificationSchedules = eventNotificationSchedules
		self.calendarEventAutoDeleteDays = calendarEventAutoDeleteDays
		self.serverRevision = serverRevision
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
		liveActivitiesEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivitiesEnabled) ?? Self.default.liveActivitiesEnabled
		appFontDesign = try container.decodeIfPresent(AppFontDesign.self, forKey: .appFontDesign) ?? Self.default.appFontDesign
		appBackground = try container.decodeIfPresent(AppBackground.self, forKey: .appBackground) ?? Self.default.appBackground
		futureEventRange = try container.decodeIfPresent(FutureEventRange.self, forKey: .futureEventRange) ?? Self.default.futureEventRange
		watchBleedEnabled = try container.decodeIfPresent(Bool.self, forKey: .watchBleedEnabled) ?? Self.default.watchBleedEnabled
		notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? Self.default.notificationsEnabled
		broadcastNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .broadcastNotificationsEnabled) ?? Self.default.broadcastNotificationsEnabled
		if let leadTimes = try container.decodeIfPresent(Set<NotificationLeadTime>.self, forKey: .notificationLeadTimes) {
			notificationLeadTimes = leadTimes
		} else if let legacyLeadTime = try legacyContainer.decodeIfPresent(NotificationLeadTime.self, forKey: .notificationLeadTime) {
			notificationLeadTimes = [legacyLeadTime]
		} else {
			notificationLeadTimes = Self.default.notificationLeadTimes
		}
		breakToPeriodNotificationLeadTimes = try container.decodeIfPresent(Set<NotificationLeadTime>.self, forKey: .breakToPeriodNotificationLeadTimes) ?? Self.default.breakToPeriodNotificationLeadTimes
		eventNotificationSchedules = try container.decodeIfPresent(Set<EventNotificationSchedule>.self, forKey: .eventNotificationSchedules) ?? Self.default.eventNotificationSchedules
		calendarEventAutoDeleteDays = try container.decodeIfPresent(Int.self, forKey: .calendarEventAutoDeleteDays) ?? Self.default.calendarEventAutoDeleteDays
		serverRevision = try container.decodeIfPresent(Int.self, forKey: .serverRevision) ?? 0
	}
}
