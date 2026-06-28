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
		settingsSync: .shared
	)

	private(set) var isBootstrapping = false

	private let ownerTimetableSync: OwnerTimetableSyncService
	private let settingsSync: AccountSettingsSyncService
	private var bootstrapTask: Task<Void, any Error>?

	private init(
		ownerTimetableSync: OwnerTimetableSyncService,
		settingsSync: AccountSettingsSyncService
	) {
		self.ownerTimetableSync = ownerTimetableSync
		self.settingsSync = settingsSync
	}

	func bootstrap() async throws {
		if let bootstrapTask {
			try await bootstrapTask.value
			return
		}

		let task = Task { @MainActor in
			async let timetable: Void = ownerTimetableSync.reconcileOwnerTimetable()
			async let settings: Void = settingsSync.downloadSettings()
			_ = try await (timetable, settings)
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
}
