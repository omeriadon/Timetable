//
//   Defaults.swift
//   Shared
//
//   Created by Adon Omeri on 12/6/2026.
//

import Defaults
import Foundation

private let sharedDefaults = UserDefaults(suiteName: "group.omeriadon.timetable") ?? UserDefaults.standard

let onboardingVersion: Int = 5

enum SharedDefaultsStore {
	static let suiteName = "group.omeriadon.timetable"

	static func removeAll() {
		let defaults = UserDefaults(suiteName: suiteName)
		let hasCompletedOnboarding = defaults?.bool(forKey: "hasCompletedOnboarding_v\(onboardingVersion)") ?? false
		let hasSeenLocationStatusWhatsNew = defaults?.bool(forKey: "hasSeenLocationStatusWhatsNew_v1") ?? false
		let persistsNavigationState = defaults?.bool(forKey: "persistsNavigationState") ?? false
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
		if hasSeenLocationStatusWhatsNew {
			defaults?.set(true, forKey: "hasSeenLocationStatusWhatsNew_v1")
		}
		defaults?.set(persistsNavigationState, forKey: "persistsNavigationState")
		for (key, value) in installationValues {
			defaults?.set(value, forKey: key)
		}
	}
}

extension Defaults.Keys {
	static let accountProfile = Key<AccountProfile?>("accountProfile", default: nil, suite: sharedDefaults)
	static let accountSettings = Key<AccountSettings>("accountSettings", default: .default, suite: sharedDefaults)

	static let hasCompletedAccountBootstrap = Key<Bool>("hasCompletedAccountBootstrap", default: false, suite: sharedDefaults)

	static let hasCompletedOnboarding = Key<Bool>("hasCompletedOnboarding_v\(onboardingVersion)", default: false, suite: sharedDefaults)
	static let onboardingPageID = Key<String>("onboardingPageID_v\(onboardingVersion)", default: "", suite: sharedDefaults)

	static let hasRegisteredAPNsToken = Key<Bool>("hasRegisteredAPNsToken", default: false, suite: sharedDefaults)
	static let pendingAPNsToken = Key<String>("pendingAPNsToken", default: "", suite: sharedDefaults)

	static let installationID = Key<String>("installationID", default: "", suite: sharedDefaults)

	static let lastServerSync = Key<Date?>("lastServerSync", default: nil, suite: sharedDefaults)
	static let pendingSyncMutations = Key<[SyncRecordMutation]>(
		"pendingSyncMutations_v1",
		default: [],
		suite: sharedDefaults
	)
	static let syncRecordRevisions = Key<SyncRecordRevisions>(
		"syncRecordRevisions_v1",
		default: .empty,
		suite: sharedDefaults
	)
	static let syncTombstones = Key<[SyncTombstone]>(
		"syncTombstones_v1",
		default: [],
		suite: sharedDefaults
	)
	static let syncCursor = Key<String?>(
		"syncCursor_v1",
		default: nil,
		suite: sharedDefaults
	)
	static let receivedNameOverrides = Key<[String: String]>("receivedNameOverrides", default: [:], suite: sharedDefaults)
	static let timetable = Key<[Subject]>("timetable", default: [], suite: sharedDefaults)
	static let gradeTracker = Key<GradeTrackerDocument>("gradeTracker", default: .empty, suite: sharedDefaults)
	static let schoolCalendar = Key<SchoolCalendarProjection>("schoolCalendar", default: .empty, suite: sharedDefaults)
	static let schoolWeather = Key<SchoolWeather?>("schoolWeather", default: nil, suite: sharedDefaults)
	static let calendarEvents = Key<CalendarEventsProjection>("calendarEvents", default: .empty, suite: sharedDefaults)
	static let friends = Key<[FriendSummary]>("friends", default: [], suite: sharedDefaults)
	static let friendDetails = Key<[FriendDetail]>("friendDetails", default: [], suite: sharedDefaults)
	static let incomingFriendRequests = Key<[FriendSummary]>("incomingFriendRequests", default: [], suite: sharedDefaults)
	static let outgoingFriendRequests = Key<[FriendSummary]>("outgoingFriendRequests", default: [], suite: sharedDefaults)
	static let locationStatus = Key<LocationStatusItem?>("locationStatus", default: nil, suite: sharedDefaults)
	static let pendingLocationStatusUpdates = Key<[LocationStatusItem]>("pendingLocationStatusUpdates", default: [], suite: sharedDefaults)
	static let hasSeenLocationStatusWhatsNew = Key<Bool>("hasSeenLocationStatusWhatsNew_v1", default: false, suite: sharedDefaults)
	static let profileAppearance = Key<ProfileAppearance>("profileAppearance", default: .default, suite: sharedDefaults)
	static let userDisplayName = Key<String>("userDisplayName", default: "Account", suite: sharedDefaults)
	static let ownerIsSearchable = Key<Bool>("ownerIsSearchable", default: true, suite: sharedDefaults)
	static let ownerTimetableID = Key<String>("ownerTimetableID", default: "", suite: sharedDefaults)
	static let hapticsEnabled = Key<Bool>("hapticsEnabled", default: true, suite: sharedDefaults)
	static let persistsNavigationState = Key<Bool>("persistsNavigationState", default: false, suite: sharedDefaults)
	static let eventTagCatalogue = Key<EventTagCatalogueResponse>("eventTagCatalogue", default: EventTagCatalogueResponse(sections: []), suite: sharedDefaults)
	static let eventTagSubscriptionIDs = Key<[UUID]>("eventTagSubscriptionIDs", default: [], suite: sharedDefaults)

	#if DEBUG
		nonisolated static let debugOffset = Key<TimeInterval>("debugOffset", default: 87896, suite: sharedDefaults)
	#else
		nonisolated static let debugOffset = Key<TimeInterval>("debugOffset", default: 0, suite: sharedDefaults)
	#endif
}
