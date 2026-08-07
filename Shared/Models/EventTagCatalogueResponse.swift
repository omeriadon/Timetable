//
//  EventTagCatalogueResponse.swift
//  Timetable
//
//  Created by Adon Omeri on 7/8/2026.
//

import Defaults
import Foundation

nonisolated struct EventTagCatalogueResponse: Codable, Defaults.Serializable, Sendable {
	let sections: [EventTagCatalogueSection]
}
