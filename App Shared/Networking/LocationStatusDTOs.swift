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
	let usersWithAssessments: Int
	let usersWithLocationStatus: Int
	let totalLocationStatusUpdates: Int
	let totalAssessments: Int
	let averageAssessmentsPerUser: Double?
	let averageAssessmentsPerUserWithMultipleAssessments: Double?
	let totalDevices: Int
	let activeDevicesLast30Days: Int
	let debugDevices: Int
	let betaDevices: Int
	let iPhoneDevices: Int
	let iPadDevices: Int
	let macDevices: Int
	let watchDevices: Int
	let legacyDevices: Int
	let acceptedFriendships: Int
	let averageFriendsPerUser: Double?
	let averageFriendsPerUserWithFriends: Double?
	let totalCalendarEvents: Int
	let globalCalendarEvents: Int
	let personalCalendarEvents: Int
	let activeEventTagSubscriptions: Int
	let averageArrivalSecondsSinceMidnight: Double?
	let deviceTypes: [AdministrationStatisticCount]
	let osVersions: [AdministrationStatisticCount]
	let deviceOSVersions: [AdministrationDeviceOSVersionCount]
}

nonisolated struct AdministrationStatisticCount: Codable, Identifiable, Sendable {
	let label: String
	let count: Int

	var id: String {
		label
	}
}

nonisolated struct AdministrationDeviceOSVersionCount: Codable, Identifiable, Sendable {
	let platform: String
	let osMajorVersion: Int
	let osMinorVersion: Int
	let count: Int

	var id: String {
		"\(platform)-\(osMajorVersion)-\(osMinorVersion)"
	}
}
