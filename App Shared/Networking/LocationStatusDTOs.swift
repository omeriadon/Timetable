//
//  LocationStatusDTOs.swift
//  App Shared
//

import Foundation

nonisolated struct LocationStatusUpdateRequest: Codable, Sendable {
	let state: LocationStatus
	let updatedAt: Date
}

nonisolated struct LocationArrivalStatisticsResponse: Codable, Sendable {
	let averageArrivalSecondsSinceMidnight: Double?
}
