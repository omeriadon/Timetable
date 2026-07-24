//
//   Defaults.swift
//   Shared
//
//   Created by Adon Omeri on 12/6/2026.
//

import Defaults
import Foundation

private let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? UserDefaults.standard

let onboardingVersion: Int = 3

enum SharedDefaultsStoreSharedDefaultsStore {
	static let suiteName = "group.omeriadon.timetable"

	static func removeAll() {
		let defaults = UserDefaults(suiteName: suiteName)
		let hasCompletedOnboarding = defaults?.bool(forKey: "hasCompletedOnboarding_v\(onboardingVersion)") ?? false
		let installationKeys = ["installationID", "installationID.iOS", "installationID.iPadOS", "installationID.macOS", "installationID.watchOS"]
		let installationValues = installationKeys.reduce(into: [String: String]()) { values, key in
			if let value = defaults?.string(forKey: key), !value.isEmpty {
				values[key] = value
			}
		}
		defaults?.removePersistentDomain(forName: suiteName)
		if hasCompletedOnboarding {
			defaults?.set(true, forKey: "hasCompletedOnboarding_v\(onboardingVersion)")
		}
		for (key, value) in installationValues {
			defaults?.set(value, forKey: key)
		}
	}
}

extension Defaults.Keys {
	static let accountProfile = Key<AccountProfile?>("accountProfile", default: nil, suite: sharedDefaults)
	static let accountSettings = Key<AccountSettings>("accountSettings", default: .default, suite: sharedDefaults)

	static let hasCompletedAccountBootstrap = Key<Bool>("hasCompletedAccountBootstrap", default: false, suite: sharedDefaults)

	// these two need version updating
	static let hasCompletedOnboarding = Key<Bool>("hasCompletedOnboarding_v\(onboardingVersion)", default: false, suite: sharedDefaults)
	static let onboardingPageID = Key<String>("onboardingPageID_v\(onboardingVersion)", default: "", suite: sharedDefaults)

	static let hasRegisteredAPNsToken = Key<Bool>("hasRegisteredAPNsToken", default: false, suite: sharedDefaults)
	static let pendingAPNsToken = Key<String>("pendingAPNsToken", default: "", suite: sharedDefaults)

	static let installationID = Key<String>("installationID", default: "", suite: sharedDefaults)

	static let lastServerSync = Key<Date?>("lastServerSync", default: nil, suite: sharedDefaults)
	static let receivedNameOverrides = Key<[String: String]>("receivedNameOverrides", default: [:], suite: sharedDefaults)
	static let timetable = Key<[Subject]>("timetable", default: [], suite: sharedDefaults)
	static let receivedTimetables = Key<[ReceivedTimetable]>("receivedTimetables", default: [], suite: sharedDefaults)
	static let authoredTimetables = Key<[TimetableDetailResponse]>("authoredTimetables", default: [], suite: sharedDefaults)
	static let pendingMessageTimetableIDs = Key<[String]>("pendingMessageTimetableIDs", default: [], suite: sharedDefaults)
	static let pendingMessageTimetableLocators = Key<[String]>("pendingMessageTimetableLocators", default: [], suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "My Timetable", suite: sharedDefaults)
	static let ownerIsSearchable = Key<Bool>("ownerIsSearchable", default: true, suite: sharedDefaults)
	static let ownerTimetableID = Key<String>("ownerTimetableID", default: "", suite: sharedDefaults)
	static let ownerTimetableShareAlias = Key<String>("ownerTimetableShareAlias", default: "", suite: sharedDefaults)
	static let hapticsEnabled = Key<Bool>("hapticsEnabled", default: true, suite: sharedDefaults)
}
