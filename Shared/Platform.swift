import Foundation

#if canImport(UIKit)
	import UIKit
#endif

enum Platform: String, Codable, Sendable, CaseIterable {
	static let appGroupSuiteName = "group.omeriadon.timetable"

	case iOS, iPadOS, macOS, watchOS
	enum Authority: String, Codable, Sendable { case authoritative, nonAuthoritative }
	var authority: Authority {
		self == .iOS ? .authoritative : .nonAuthoritative
	}

	var isAuthoritative: Bool {
		authority == .authoritative
	}

	var allowsAccountCreation: Bool {
		self == .iOS
	}

	var allowsOwnerMutation: Bool {
		self == .iOS
	}

	var allowsAuthoredTimetableMutation: Bool {
		self == .iOS
	}

	var allowsReceivedTimetableMutation: Bool {
		self == .iOS
	}

	var allowsSharing: Bool {
		self == .iOS
	}

	var allowsEditing: Bool {
		self == .iOS
	}

	var allowsNotificationSettings: Bool {
		true
	}

	var requiresAuthenticatedSession: Bool {
		true
	}

	static var current: Platform {
		#if os(macOS)
			.macOS
		#elseif os(watchOS)
			.watchOS
		#elseif os(iOS)
			UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
		#else
			.iOS
		#endif
	}
}

enum PlatformPolicyError: Error, LocalizedError, Equatable {
	case platformActionUnavailable
	var errorDescription: String? {
		"This action is unavailable on the current platform."
	}
}

struct ClientIdentity: Codable, Sendable, Equatable {
	let platform: Platform
	let installationID: String
}

struct ClientIdentityProvider {
	private let defaults: UserDefaults
	init(defaults: UserDefaults = UserDefaults(suiteName: Platform.appGroupSuiteName) ?? .standard) {
		self.defaults = defaults
	}

	func identity(for platform: Platform = .current) -> ClientIdentity {
		let key = "installationID.\(platform.rawValue)"
		if let existing = defaults.string(forKey: key), !existing.isEmpty {
			return ClientIdentity(platform: platform, installationID: existing)
		}
		let id = platform == .iOS ? (defaults.string(forKey: "installationID").flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString) : UUID().uuidString
		defaults.set(id, forKey: key)
		return ClientIdentity(platform: platform, installationID: id)
	}

	static let shared = ClientIdentityProvider()
}

extension Platform {
	static func require(_ allowed: Bool) throws {
		guard allowed else { throw PlatformPolicyError.platformActionUnavailable }
	}
}
