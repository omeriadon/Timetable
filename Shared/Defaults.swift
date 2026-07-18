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
	private static let resetMarker = "com.omeriadon.Timetable.sharedDefaultsResetVersion"
	private static let currentResetVersion = 1

	/// Removes the pre-release shared defaults once when this release first launches.
	/// The marker lives in the app's standard defaults so clearing the app-group suite
	/// cannot cause the reset to repeat on every launch.
	static func resetPreReleaseStateIfNeeded() {
		let markerDefaults = UserDefaults.standard
		guard markerDefaults.integer(forKey: resetMarker) < currentResetVersion else { return }

		let defaults = UserDefaults(suiteName: suiteName) ?? markerDefaults
		defaults.removePersistentDomain(forName: suiteName)
		markerDefaults.set(currentResetVersion, forKey: resetMarker)
	}

	static func removeAll() {
		UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
	}
}

extension Defaults.Keys {
	static let accountProfile = Key<AccountProfile?>("accountProfile", default: nil, suite: sharedDefaults)
	static let accountSettings = Key<AccountSettings>("accountSettings", default: .default, suite: sharedDefaults)

	static let hasCompletedAccountBootstrap = Key<Bool>("hasCompletedAccountBootstrap", default: false, suite: sharedDefaults)
	static let hasCompletedOnboarding = Key<Bool>("hasCompletedOnboarding", default: false, suite: sharedDefaults)
	static let hasSeenOnboardingBefore = Key<Bool>("hasSeenOnboardingBefore.v2", default: false, suite: sharedDefaults)
	static let onboardingPageID = Key<String>("onboardingPageID.v2", default: "", suite: sharedDefaults)
	static let hasRegisteredAPNsToken = Key<Bool>("hasRegisteredAPNsToken", default: false, suite: sharedDefaults)
	static let pendingAPNsToken = Key<String>("pendingAPNsToken", default: "", suite: sharedDefaults)

	static let installationID = Key<String>("installationID", default: "", suite: sharedDefaults)

	static let lastServerSync = Key<Date?>("lastServerSync", default: nil, suite: sharedDefaults)
	static let receivedNameOverrides = Key<[String: String]>("receivedNameOverrides", default: [:], suite: sharedDefaults)
	static let timetable = Key<[Subject]>("timetable", default: [], suite: sharedDefaults)
	static let receivedTimetables = Key<[ReceivedTimetable]>("receivedTimetables", default: [], suite: sharedDefaults)
	static let pendingMessageTimetableIDs = Key<[String]>("pendingMessageTimetableIDs", default: [], suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "My Timetable", suite: sharedDefaults)
	static let ownerIsSearchable = Key<Bool>("ownerIsSearchable", default: true, suite: sharedDefaults)
	static let ownerTimetableID = Key<String>("ownerTimetableID", default: "", suite: sharedDefaults)
	static let timetableHighlightsCurrentDay = Key<Bool>("timetableHighlightsCurrentDay", default: true, suite: sharedDefaults)
	static let hapticsEnabled = Key<Bool>("hapticsEnabled", default: true, suite: sharedDefaults)
}
