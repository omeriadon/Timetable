//
//   AccountSettingsSyncService.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class AccountSettingsSyncService {
	static let shared = AccountSettingsSyncService(networkManager: .shared)

	private(set) var isSyncing = false

	private let networkManager: NetworkManager
	private var pendingMutation: PendingMutation?
	private var syncGeneration = 0
	private var syncTask: Task<Void, any Error>?

	private struct PendingMutation {
		let settings: AccountSettings
		let previousSettings: AccountSettings
		let generation: Int
	}

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func updateSettings(_ settings: AccountSettings) async throws {
		let previousSettings = Defaults[.accountSettings]
		syncGeneration += 1
		pendingMutation = PendingMutation(
			settings: settings,
			previousSettings: previousSettings,
			generation: syncGeneration
		)
		Defaults[.accountSettings] = settings
		applyLocalSideEffects()
		try await synchronizePendingSettings()
	}

	func flushPendingSettings() async throws {
		if pendingMutation == nil {
			syncGeneration += 1
			let settings = Defaults[.accountSettings]
			pendingMutation = PendingMutation(
				settings: settings,
				previousSettings: settings,
				generation: syncGeneration
			)
		}
		try await synchronizePendingSettings()
	}

	func downloadSettings() async throws {
		let remoteSettings: AccountSettings = try await networkManager.send(.v1Settings)
		Defaults[.accountSettings] = remoteSettings
		Defaults[.lastServerSync] = Date.now
		pendingMutation = nil
		applyLocalSideEffects()
	}

	private func synchronizePendingSettings() async throws {
		if let syncTask {
			do {
				try await syncTask.value
			} catch {
				self.syncTask = nil
				isSyncing = false
				if pendingMutation != nil {
					try await synchronizePendingSettings()
					return
				}
				throw error
			}
			self.syncTask = nil
			isSyncing = false
			if pendingMutation != nil {
				try await synchronizePendingSettings()
			}
			return
		}

		let generation = syncGeneration
		let task = Task { @MainActor in
			try await drainPendingMutations()
		}
		syncTask = task
		isSyncing = true
		defer {
			if syncGeneration == generation || pendingMutation == nil {
				syncTask = nil
				isSyncing = false
			}
		}
		try await task.value
	}

	private func drainPendingMutations() async throws {
		while let mutation = pendingMutation {
			try Task.checkCancellation()
			pendingMutation = nil

			do {
				let _: AccountSettings = try await networkManager.send(
					.v1SettingsUpdate,
					body: mutation.settings
				)
				Defaults[.lastServerSync] = Date.now
				#if os(iOS)
					if mutation.settings.liveActivitiesEnabled,
					   !mutation.previousSettings.liveActivitiesEnabled
					{
						await LiveActivityRegistrationService.shared.reconcileAuthorization(requestStartIfNeeded: true)
					}
				#endif
			} catch let NetworkError.server(_, response) where response.code == .invalidRequest {
				if syncGeneration == mutation.generation {
					Defaults[.accountSettings] = mutation.previousSettings
					applyLocalSideEffects()
				}
				throw NetworkError.server(statusCode: 400, response: response)
			} catch {
				if syncGeneration == mutation.generation {
					Defaults[.accountSettings] = mutation.previousSettings
					pendingMutation = nil
					applyLocalSideEffects()
				}
				throw error
			}
		}
	}

	private func applyLocalSideEffects() {
		WidgetCenter.shared.reloadAllTimelines()
		#if os(iOS)
			Task {
				await LiveActivityRegistrationService.shared.reconcileAuthorization()
			}
		#endif
	}
}

private extension Endpoint {
	static let v1Settings = Endpoint("/v1/settings")
	static let v1SettingsUpdate = Endpoint("/v1/settings", method: .put)
}
