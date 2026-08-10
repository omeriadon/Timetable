//
//  LocationStatus.swift
//  Shared
//

import Defaults
import Foundation

nonisolated enum LocationStatus: String, Codable, CaseIterable, Sendable {
	case offCampus
	case withinTenMinutes
	case withinFiveMinutes
	case onCampus
}

nonisolated enum LocationNotificationPreference: String, Codable, CaseIterable, Hashable, Sendable {
	case withinTenMinutes
	case withinFiveMinutes
	case arrived
}

nonisolated struct LocationStatusItem: Codable, Defaults.Serializable, Hashable, Sendable {
	let state: LocationStatus
	let updatedAt: Date
}
