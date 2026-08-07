//
//  LocationStatusDTOs.swift
//  App Shared
//

import Foundation

nonisolated struct LocationStatusUpdateRequest: Codable, Sendable {
	let state: LocationStatus
	let updatedAt: Date
}

nonisolated struct LocationStatusCurrentResponse: Codable, Sendable {
	let item: LocationStatusItem?
}

nonisolated struct LocationArrivalStatisticsResponse: Codable, Sendable {
	let averageArrivalSecondsSinceMidnight: Double?
}

nonisolated struct AdministrationStatisticsResponse: Codable, Sendable {
	let totalUsers: Int
	let usersWithOwnerTimetable: Int
	let activeDevicesLast30Days: Int
	let acceptedFriendships: Int
	let totalCalendarEvents: Int
	let globalCalendarEvents: Int
	let personalCalendarEvents: Int
	let activeEventTagSubscriptions: Int
	let averageArrivalSecondsSinceMidnight: Double?
}
