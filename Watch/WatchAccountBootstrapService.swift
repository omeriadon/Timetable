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
			async let settings: AccountSettings = networkManager.send(.v1Settings)
			async let received: [ReceivedPassMirrorDTO] = networkManager.send(.v1ReceivedTimetables)
			async let overrides: [ReceivedNameOverrideResponse] = networkManager.send(.v1ReceivedNameOverrides)
			let (ownerTimetable, remoteSettings, receivedTimetables, receivedOverrides) = try await (
				timetable,
				settings,
				received,
				overrides
			)

			Defaults[.timetable] = ownerTimetable.subjects
			Defaults[.accountSettings] = remoteSettings
			let names = Dictionary(
				uniqueKeysWithValues: receivedOverrides.map { ($0.serialNumber, $0.displayName) }
			)
			Defaults[.receivedNameOverrides] = names
			Defaults[.receivedTimetables] = receivedTimetables
				.filter { !$0.isDeleted }
				.map { dto in
					var timetable = dto.receivedTimetable
					timetable.sender = names[dto.id] ?? dto.signedDisplayName
					return timetable
				}
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
	static let v1ReceivedTimetables = Endpoint("/v1/timetables/received")
	static let v1ReceivedNameOverrides = Endpoint("/v1/received-name-overrides")
}
