//
//   Defaults.swift
//   Shared
//
//   Created by Adon Omeri on 12/6/2026.
//

import Defaults
import Foundation

private let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? UserDefaults.standard

extension Defaults.Keys {
	static let accountProfile = Key<AccountProfile?>("accountProfile", default: nil, suite: sharedDefaults)
	static let accountSettings = Key<AccountSettings>("accountSettings", default: .default, suite: sharedDefaults)
	static let hasCompletedAccountBootstrap = Key<Bool>("hasCompletedAccountBootstrap", default: false, suite: sharedDefaults)
	static let installationID = Key<String>("installationID", default: "", suite: sharedDefaults)
	static let lastServerSync = Key<Date?>("lastServerSync", default: nil, suite: sharedDefaults)
	static let lastWalletReconciliation = Key<Date?>("lastWalletReconciliation", default: nil, suite: sharedDefaults)
	static let receivedNameOverrides = Key<[String: String]>("receivedNameOverrides", default: [:], suite: sharedDefaults)
	static let timetable = Key<[Subject]>("timetable", default: [], suite: sharedDefaults)
	static let receivedTimetables = Key<[ReceivedTimetable]>("receivedTimetables", default: [], suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "My Timetable", suite: sharedDefaults)
	static let walletRevision = Key<Int>("walletRevision", default: 0, suite: sharedDefaults)
	static let ownerIsSearchable = Key<Bool>("ownerIsSearchable", default: true, suite: sharedDefaults)
}
