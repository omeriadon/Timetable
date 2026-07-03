//
//   Teacher.swift
//   Shared
//

import Foundation

nonisolated enum Teacher: Codable, Hashable {
	case named(lastName: String)
	case unknown(rawNotes: String)

	init(rawNotes: String) {
		let trimmed = rawNotes.trimmingCharacters(in: .whitespacesAndNewlines)
		let prefix = "Attending Staff : "

		guard trimmed.hasPrefix(prefix) else {
			self = .unknown(rawNotes: rawNotes)
			return
		}

		let staffCode = String(trimmed.dropFirst(prefix.count))
		guard staffCode.count >= 2, staffCode.allSatisfy(\.isLetter) else {
			self = .unknown(rawNotes: rawNotes)
			return
		}

		let surname = String(staffCode.dropFirst()).lowercased().capitalized
		self = .named(lastName: surname)
	}

	var displayName: String {
		switch self {
			case let .named(lastName): lastName
			case let .unknown(rawNotes): rawNotes
		}
	}

	var editorValue: String {
		switch self {
			case let .named(lastName): lastName
			case let .unknown(rawNotes): rawNotes
		}
	}

	static func editorValue(_ value: String) -> Teacher {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return .unknown(rawNotes: value) }
		return .named(lastName: trimmed)
	}
}
