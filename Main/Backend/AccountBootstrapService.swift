//
//   AccountBootstrapService.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class AccountBootstrapService {
	static let shared = AccountBootstrapService(
		ownerTimetableSync: .shared,
		settingsSync: .shared,
		friendService: .shared,
		schoolCalendarSync: .shared,
		calendarEventsSync: .shared
	)

	private(set) var isBootstrapping = false

	private let ownerTimetableSync: OwnerTimetableSyncService
	private let settingsSync: AccountSettingsSyncService
	private let friendService: FriendService
	private let schoolCalendarSync: SchoolCalendarSyncService
	private let calendarEventsSync: CalendarEventsSyncService
	private var bootstrapTask: Task<Void, any Error>?

	private init(
		ownerTimetableSync: OwnerTimetableSyncService,
		settingsSync: AccountSettingsSyncService,
		friendService: FriendService,
		schoolCalendarSync: SchoolCalendarSyncService,
		calendarEventsSync: CalendarEventsSyncService
	) {
		self.ownerTimetableSync = ownerTimetableSync
		self.settingsSync = settingsSync
		self.friendService = friendService
		self.schoolCalendarSync = schoolCalendarSync
		self.calendarEventsSync = calendarEventsSync
	}

	func bootstrap() async throws {
		if let bootstrapTask {
			try await bootstrapTask.value
			return
		}

		let task = Task<Void, any Error> { @MainActor in
			async let account: Void = self.runBootstrapStage("Account") {
				_ = try await SessionStore.shared.refreshProfile()
			}
			async let timetable: Void = self.runBootstrapStage("Owner timetable") {
				try await self.ownerTimetableSync.reconcileOwnerTimetable()
				await TimetableShareAliasService.shared.fetchCurrentAlias()
			}
			async let settings: Void = self.runBootstrapStage("Account settings") {
				try await self.settingsSync.downloadSettings()
			}
			async let friends: Void = self.runBootstrapStage("Friends") {
				try await self.friendService.refresh()
			}
			async let created: Void = self.runBootstrapStage("Created timetables") {
				try await CreatedTimetableService.shared.refresh()
			}
			async let schoolCalendar: Void = self.runBootstrapStage("School calendar") {
				try await self.schoolCalendarSync.downloadCalendar()
			}
			async let calendarEvents: Void = self.runBootstrapStage("Calendar events") {
				try await self.calendarEventsSync.downloadEvents()
			}
			_ = await (account, timetable, settings, friends, created, schoolCalendar, calendarEvents)
		}
		bootstrapTask = task
		isBootstrapping = true
		defer {
			bootstrapTask = nil
			isBootstrapping = false
		}
		try await task.value
		Defaults[.hasCompletedAccountBootstrap] = true
		Defaults[.lastServerSync] = Date.now
	}

	private func runBootstrapStage(_ name: String, operation: @escaping @MainActor () async throws -> Void) async {
		do {
			try await operation()
		} catch {
			PrintError("\(name) bootstrap failed", category: .account, error: error)
		}
	}
}
