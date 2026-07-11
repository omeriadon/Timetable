//
//   Defaults.swift
//   Shared
//
//   Created by Adon Omeri on 12/6/2026.
//

import Defaults
import Foundation

private let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? UserDefaults.standard

enum SharedDefaultsStore {
	static let suiteName = "group.omeriadon.timetable"

	static func removeAll() {
		UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
	}
}

extension Defaults.Keys {
	static let accountProfile = Key<AccountProfile?>("accountProfile", default: nil, suite: sharedDefaults)
	static let accountSettings = Key<AccountSettings>("accountSettings", default: .default, suite: sharedDefaults)

	static let hasCompletedAccountBootstrap = Key<Bool>("hasCompletedAccountBootstrap", default: false, suite: sharedDefaults)
	static let hasCompletedOnboarding = Key<Bool>("hasCompletedOnboarding", default: false, suite: sharedDefaults)
	static let hasRegisteredAPNsToken = Key<Bool>("hasRegisteredAPNsToken", default: false, suite: sharedDefaults)
	static let pendingAPNsToken = Key<String>("pendingAPNsToken", default: "", suite: sharedDefaults)

	static let installationID = Key<String>("installationID", default: "", suite: sharedDefaults)

	static let lastServerSync = Key<Date?>("lastServerSync", default: nil, suite: sharedDefaults)
	static let lastWalletReconciliation = Key<Date?>("lastWalletReconciliation", default: nil, suite: sharedDefaults)

	static let receivedNameOverrides = Key<[String: String]>("receivedNameOverrides", default: [:], suite: sharedDefaults)
	static let timetable = Key<[Subject]>("timetable", default: [], suite: sharedDefaults)
	static let receivedTimetables = Key<[ReceivedTimetable]>("receivedTimetables", default: [], suite: sharedDefaults)
	static let receivedTombstoneIDs = Key<Set<String>>("receivedTombstoneIDs", default: [], suite: sharedDefaults)
	static let installedWalletTimetableIDs = Key<Set<String>>("installedWalletTimetableIDs", default: [], suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "My Timetable", suite: sharedDefaults)
	static let walletRevision = Key<Int>("walletRevision", default: 0, suite: sharedDefaults)
	static let ownerIsSearchable = Key<Bool>("ownerIsSearchable", default: true, suite: sharedDefaults)
	static let timetableHighlightsCurrentDay = Key<Bool>("timetableHighlightsCurrentDay", default: true, suite: sharedDefaults)
}
