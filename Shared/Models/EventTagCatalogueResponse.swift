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

nonisolated struct EventTagCatalogueSection: Codable, Identifiable, Sendable {
	let id: UUID
	let category: AdministrationEventTagCategory
	let displayName: String
	let tags: [EventTagCatalogueTag]
}

nonisolated enum AdministrationEventTagCategory: String, Codable, CaseIterable, Sendable, Identifiable {
	case yearGroup
	case subject
	case sport
	case general

	var id: String {
		rawValue
	}

	var displayName: String {
		switch self {
			case .yearGroup:
				"Year Groups"
			case .subject:
				"Subjects"
			case .sport:
				"Sports"
			case .general:
				"General"
		}
	}
}

nonisolated struct EventTagCatalogueTag: Codable, Identifiable, Sendable {
	let id: UUID
	let displayName: String
	let category: AdministrationEventTagCategory
	let symbol: String?
	let colorHex: String?
	let associatedNames: [String]

	private enum CodingKeys: String, CodingKey {
		case id
		case displayName
		case category
		case symbol
		case colorHex
		case associatedNames
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		displayName = try container.decode(String.self, forKey: .displayName)
		category = try container.decode(AdministrationEventTagCategory.self, forKey: .category)
		symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
		colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
		associatedNames = try container.decodeIfPresent([String].self, forKey: .associatedNames) ?? [displayName]
	}
}
