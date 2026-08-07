import Foundation

#if canImport(UIKit)
	import UIKit
#endif

enum Platform: String, Codable, Sendable, CaseIterable {
	static let appGroupSuiteName = "group.omeriadon.timetable"

	case iOS, iPadOS, macOS, watchOS

	var allowsAccountCreation: Bool {
		self != .watchOS
	}

	var allowsAppleAuthentication: Bool {
		self == .iOS || self == .iPadOS || self == .macOS
	}

	var allowsOwnerMutation: Bool {
		self != .watchOS
	}

	var allowsCreatedTimetableMutation: Bool {
		self != .watchOS
	}

	var allowsReceivedTimetableMutation: Bool {
		self != .watchOS
	}

	var allowsSharing: Bool {
		self != .watchOS
	}

	var allowsEditing: Bool {
		self != .watchOS
	}

	var allowsNotificationSettings: Bool {
		true
	}

	var requiresAuthenticatedSession: Bool {
		true
	}

	static var current: Platform {
		#if os(watchOS)
			.watchOS
		#elseif targetEnvironment(macCatalyst)
			.macOS
		#elseif os(iOS)
			UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
		#else
			.iOS
		#endif
	}

	static func require(_ allowed: Bool) throws {
		guard allowed else {
			throw PlatformPolicyError.platformActionUnavailable
		}
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
