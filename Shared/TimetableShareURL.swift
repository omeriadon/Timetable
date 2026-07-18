import Defaults
import Foundation

enum TimetableShareURL {
	static let host = "timetable.adonis.pt"
	static let pathPrefix = "/sharedtimetable/"

	static func ownerURL(id: UUID, alias: String = Defaults[.ownerTimetableShareAlias]) -> URL? {
		if !alias.isEmpty, TimetableShareAliasValidator.validate(alias) == nil {
			return url(locator: alias)
		}
		return url(locator: id.uuidString)
	}

	static func url(locator: String) -> URL? {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		components.path = pathPrefix + locator
		return components.url
	}

	static func locator(from url: URL) -> String? {
		guard url.scheme == "https", url.host == host else { return nil }
		let components = url.pathComponents
		guard components.count == 3, components[1] == "sharedtimetable", components[2].utf8.count <= TimetableShareAliasValidator.maximumLength else { return nil }
		return components[2]
	}
}

enum TimetableShareAliasValidationReason: String, Codable, Sendable {
	case empty, tooShort, tooLong, invalidCharacter, leadingSeparator, trailingSeparator, consecutiveSeparators, reserved, uuidShaped
}

struct TimetableShareAliasValidationError: Error, Equatable, Sendable {
	let reason: TimetableShareAliasValidationReason
	let character: Character?
	let index: Int?
}

enum TimetableShareAliasValidator {
	static let minimumLength = 3
	static let maximumLength = 30
	static let reserved: Set<String> = ["api", "v1", "health", "admin", "account", "auth", "login", "logout", "settings", "search", "share", "shared", "sharedtimetable", "timetable", "timetables", "messages", "support", "privacy", "terms", "null", "undefined", "me", "owner"]

	static func canonicalize(_ raw: String) -> String {
		raw.lowercased()
	}

	static func validate(_ raw: String) -> TimetableShareAliasValidationError? {
		let value = canonicalize(raw)
		guard !value.isEmpty else { return .init(reason: .empty, character: nil, index: nil) }
		guard UUID(uuidString: value) == nil else { return .init(reason: .uuidShaped, character: nil, index: nil) }
		guard value.count >= minimumLength else { return .init(reason: .tooShort, character: nil, index: nil) }
		guard value.count <= maximumLength else { return .init(reason: .tooLong, character: nil, index: nil) }
		let chars = Array(value)
		for (index, char) in chars.enumerated() {
			let scalarOK = char.unicodeScalars.allSatisfy(\.isASCII)
			guard scalarOK, char.isLetter || char.isNumber || char == "-" || char == "_" else { return .init(reason: .invalidCharacter, character: char, index: index) }
		}
		if chars.first == "-" || chars.first == "_" {
			return .init(reason: .leadingSeparator, character: chars[0], index: 0)
		}
		if chars.last == "-" || chars.last == "_" {
			return .init(reason: .trailingSeparator, character: chars[chars.count - 1], index: chars.count - 1)
		}
		for index in 1 ..< chars.count where isSeparator(chars[index - 1]) && isSeparator(chars[index]) {
			return .init(reason: .consecutiveSeparators, character: chars[index], index: index)
		}
		if reserved.contains(value) {
			return .init(reason: .reserved, character: nil, index: nil)
		}
		return nil
	}

	static func validateAndCanonicalize(_ raw: String) throws -> String {
		let value = canonicalize(raw)
		if let error = validate(value) {
			throw error
		}
		return value
	}

	private static func isSeparator(_ char: Character) -> Bool {
		char == "-" || char == "_"
	}
}
