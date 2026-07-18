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
			async let received: [AuthoritativeReceivedTimetableDTO] = networkManager.send(.v1ReceivedTimetables)
			let (ownerTimetable, remoteSettings, receivedTimetables) = try await (
				timetable,
				settings,
				received
			)

			Defaults[.timetable] = ownerTimetable.subjects
			Defaults[.accountSettings] = remoteSettings
			Defaults[.receivedTimetables] = receivedTimetables
				.filter { $0.availability == .available }
				.map(\.receivedTimetable)
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
	static let v1ReceivedTimetables = Endpoint("/v1/timetables/received/authoritative", queryItems: [URLQueryItem(name: "limit", value: "50")])
}
