//
//  TimetableEntity.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct TimetableEntity: Codable, Defaults.Serializable, AppEntity {
	static var defaultQuery = TimetableQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Timetable")

	var id: String

	@Property(title: "Owner")
	private(set) var storedOwnerType: OwnerType

	@Property(title: "Subjects")
	var subjects: Timetable

	@Property(title: "Shared Info")
	var sharedInfo: SharedInfo? {
		didSet {
			self.storedOwnerType = self.sharedInfo == nil ? .user : .shared
		}
	}

	init(id: String, ownerType: OwnerType, subjects: Timetable, sender: String? = nil, receivedAt: Date? = nil) {
		self.id = id
		self.subjects = subjects
		if let sender, let receivedAt {
			self.sharedInfo = SharedInfo(receivedAt: receivedAt, sender: sender)
		}
	}

	var displayRepresentation: DisplayRepresentation {
		let string = {
			switch self.storedOwnerType {
				case .user:
					return "Your timetable"
				case .shared:
					if let sender = sharedInfo?.sender {
						return "\(sender)'s Timetable"
					}
					return "Shared timetable"
			}
		}()

		return DisplayRepresentation(stringLiteral: string)
	}
}

struct SharedInfo: Codable, Identifiable, TransientAppEntity {
	var id: String {
		"\(self.sender)\(self.receivedAt.description)"
	}

	static let typeDisplayRepresentation = TypeDisplayRepresentation(stringLiteral: "Owner")
	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: "\(self.sender)'s Timetable")
	}

	var receivedAt: Date
	var sender: String

	init() {
		self.receivedAt = Date()
		self.sender = ""
	}

	init(receivedAt: Date, sender: String) {
		self.receivedAt = receivedAt
		self.sender = sender
	}
}

enum OwnerType: String, Codable, AppEnum, CaseIterable, Identifiable {
	var id: String {
		self.rawValue
	}

	static let typeDisplayRepresentation = TypeDisplayRepresentation(stringLiteral: "Owner")

	static let caseDisplayRepresentations: [OwnerType: DisplayRepresentation] = [
		.user: DisplayRepresentation(stringLiteral: "Your timetable"),
		.shared: DisplayRepresentation(stringLiteral: "Shared timetable")
	]

	case user = "Your timetable"
	case shared = "Shared timetable"
}
