//
//  LocationStatus.swift
//  Shared
//

import Defaults
import Foundation

nonisolated enum LocationStatus: String, Codable, CaseIterable, Sendable {
	case onCampus
	case offCampus
}

nonisolated struct LocationStatusItem: Codable, Defaults.Serializable, Hashable, Sendable {
	let state: LocationStatus
	let updatedAt: Date
}
