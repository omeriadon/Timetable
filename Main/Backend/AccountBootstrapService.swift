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
		receivedTimetableSync: .shared
	)

	private(set) var isBootstrapping = false

	private let ownerTimetableSync: OwnerTimetableSyncService
	private let settingsSync: AccountSettingsSyncService
	private let receivedTimetableSync: ReceivedTimetableSyncService
	private var bootstrapTask: Task<Void, any Error>?

	private init(
		ownerTimetableSync: OwnerTimetableSyncService,
		settingsSync: AccountSettingsSyncService,
		receivedTimetableSync: ReceivedTimetableSyncService
	) {
		self.ownerTimetableSync = ownerTimetableSync
		self.settingsSync = settingsSync
		self.receivedTimetableSync = receivedTimetableSync
	}

	func bootstrap() async throws {
		if let bootstrapTask {
			try await bootstrapTask.value
			return
		}

		let task = Task<Void, any Error> { @MainActor in
			async let timetable: Void = self.runBootstrapStage("Owner timetable") {
				if Platform.current.allowsOwnerMutation {
					try await self.ownerTimetableSync.reconcileOwnerTimetable()
				} else {
					try await self.ownerTimetableSync.downloadOwnerTimetable()
				}
			}
			async let settings: Void = self.runBootstrapStage("Account settings") {
				// Notification preferences are device-local on non-authoritative clients.
				if Platform.current.isAuthoritative {
					try await self.settingsSync.downloadSettings()
				}
			}
			async let received: Void = self.runBootstrapStage("Received timetables") {
				try await self.receivedTimetableSync.downloadProjectionAndOverrides()
			}
			_ = await (timetable, settings, received)
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
