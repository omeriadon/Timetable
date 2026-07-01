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

		let task = Task { @MainActor in
			async let timetable: Void = ownerTimetableSync.reconcileOwnerTimetable()
			async let settings: Void = settingsSync.downloadSettings()
			async let received: Void = receivedTimetableSync.downloadProjectionAndOverrides()
			_ = try await (timetable, settings, received)
			#if os(iOS)
				await NotificationRegistrationService.shared.reconcileWithStoredPreference()
			#endif
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
