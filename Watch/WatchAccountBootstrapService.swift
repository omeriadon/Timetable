//
//   WatchAccountBootstrapService.swift
//   Watch
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class WatchAccountBootstrapService {
	static let shared = WatchAccountBootstrapService(networkManager: .shared)

	private(set) var isSyncing = false

	private let networkManager: NetworkManager
	private var syncTask: Task<Void, any Error>?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func bootstrap() async throws {
		if let syncTask {
			try await syncTask.value
			return
		}

		let task = Task { @MainActor in
			async let timetable: OwnerTimetableResponse = networkManager.send(.v1OwnerTimetable)
			async let settings: RemoteAccountSettings = networkManager.send(.v1Settings)
			let (ownerTimetable, remoteSettings) = try await (timetable, settings)

			Defaults[.timetable] = ownerTimetable.subjects
			var accountSettings = Defaults[.accountSettings]
			accountSettings.liveActivitiesEnabled = remoteSettings.liveActivitiesEnabled
			Defaults[.accountSettings] = accountSettings
			Defaults[.lastServerSync] = Date.now
			Defaults[.hasCompletedAccountBootstrap] = true
			WidgetCenter.shared.reloadAllTimelines()
		}
		syncTask = task
		isSyncing = true
		defer {
			syncTask = nil
			isSyncing = false
		}
		try await task.value
	}
}

private extension Endpoint {
	static let v1OwnerTimetable = Endpoint("/v1/timetables/owner")
	static let v1Settings = Endpoint("/v1/settings")
}
