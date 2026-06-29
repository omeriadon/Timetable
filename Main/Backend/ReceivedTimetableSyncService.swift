//
//   ReceivedTimetableSyncService.swift
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
final class ReceivedTimetableSyncService {
	static let shared = ReceivedTimetableSyncService(networkManager: .shared)

	private(set) var isSyncing = false

	private let networkManager: NetworkManager
	private var syncTask: Task<Void, any Error>?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func uploadCurrentProjection() async throws {
		let walletRevision = Defaults[.walletRevision]
		let request = ReceivedProjectionUpdateRequest(
			timetables: Defaults[.receivedTimetables].map {
				ReceivedPassMirrorDTO($0, walletRevision: walletRevision)
			},
			walletRevision: walletRevision
		)
		let response: [ReceivedPassMirrorDTO] = try await networkManager.send(
			.v1ReceivedTimetablesUpdate,
			body: request
		)
		apply(response)
	}

	func downloadProjectionAndOverrides() async throws {
		if let syncTask {
			try await syncTask.value
			return
		}

		let task = Task { @MainActor in
			async let projection: [ReceivedPassMirrorDTO] = networkManager.send(.v1ReceivedTimetables)
			async let overrides: [ReceivedNameOverrideResponse] = networkManager.send(.v1ReceivedNameOverrides)
			let (received, names) = try await (projection, overrides)
			Defaults[.receivedNameOverrides] = Dictionary(
				uniqueKeysWithValues: names.map { ($0.serialNumber, $0.displayName) }
			)
			apply(received)
		}
		syncTask = task
		isSyncing = true
		defer {
			syncTask = nil
			isSyncing = false
		}
		try await task.value
	}

	func setReceivedNameOverride(serialNumber: String, displayName: String) async throws {
		let response: ReceivedNameOverrideResponse = try await networkManager.send(
			.v1ReceivedNameOverride(serialNumber),
			body: UpdateReceivedNameOverrideRequest(displayName: displayName)
		)
		Defaults[.receivedNameOverrides][response.serialNumber] = response.displayName
		applyLocalNames()
	}

	func removeReceivedNameOverride(serialNumber: String) async throws {
		try await networkManager.send(.v1ReceivedNameOverrideDelete(serialNumber))
		try await downloadProjectionAndOverrides()
	}

	private func apply(_ response: [ReceivedPassMirrorDTO]) {
		Defaults[.receivedTimetables] = response
			.filter { !$0.isDeleted }
			.map(\.receivedTimetable)
		applyLocalNames()
		Defaults[.lastServerSync] = Date.now
		WidgetCenter.shared.reloadAllTimelines()
	}

	private func applyLocalNames() {
		WidgetCenter.shared.reloadAllTimelines()
	}
}

private extension Endpoint {
	static let v1ReceivedTimetables = Endpoint("/v1/timetables/received")
	static let v1ReceivedTimetablesUpdate = Endpoint("/v1/timetables/received", method: .put)
	static let v1ReceivedNameOverrides = Endpoint("/v1/received-name-overrides")

	static func v1ReceivedNameOverride(_ serialNumber: String) -> Endpoint {
		Endpoint("/v1/received-name-overrides/\(serialNumber)", method: .put)
	}

	static func v1ReceivedNameOverrideDelete(_ serialNumber: String) -> Endpoint {
		Endpoint("/v1/received-name-overrides/\(serialNumber)", method: .delete)
	}
}
