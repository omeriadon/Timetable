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
	private var uploadTask: Task<Void, any Error>?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func uploadCurrentProjection() async throws {
		if let uploadTask {
			try await uploadTask.value
			return
		}

		let task = Task { @MainActor in
			let walletRevision = Defaults[.walletRevision]
			let request = ReceivedProjectionUpdateRequest(
				timetables: Defaults[.receivedTimetables].map {
					ReceivedPassMirrorDTO($0, walletRevision: walletRevision)
				},
				walletRevision: walletRevision
			)
			let existing: [ReceivedPassMirrorDTO] = try await networkManager.send(.v1ReceivedTimetables)
			let currentIDs = Set(request.timetables.map(\.id))
			for existingTimetable in existing where !currentIDs.contains(existingTimetable.id) {
				try await networkManager.send(.v1ReceivedTimetableDelete(existingTimetable.id), context: .userInitiated)
			}
			for timetable in request.timetables {
				let _: [ReceivedPassMirrorDTO] = try await networkManager.send(
					.v1ReceivedTimetableUpdate(timetable.id),
					body: requestFor(timetable: timetable, walletRevision: walletRevision)
				)
			}
			try await downloadProjectionAndOverrides()
		}
		uploadTask = task
		isSyncing = true
		defer {
			uploadTask = nil
			isSyncing = false
		}
		try await withTaskCancellationHandler {
			try await task.value
		} onCancel: {
			task.cancel()
		}
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

	func deleteReceivedTimetable(serialNumber: String) async throws {
		try await networkManager.send(.v1ReceivedTimetableDelete(serialNumber), context: .userInitiated)
		Defaults[.receivedTombstoneIDs].insert(serialNumber)
		Defaults[.receivedTimetables].removeAll { $0.id == serialNumber }
		Task { await SpotlightIndexer.shared.removeDeletedTimetables() }
		WidgetCenter.shared.reloadAllTimelines()
	}

	private func apply(_ response: [ReceivedPassMirrorDTO]) {
		let tombstones = Set(response.filter(\.isDeleted).map(\.id))
		Defaults[.receivedTombstoneIDs].formUnion(tombstones)
		var merged = Dictionary(uniqueKeysWithValues: Defaults[.receivedTimetables].map { ($0.id, $0) })
		for dto in response where !dto.isDeleted {
			let incoming = dto.receivedTimetable
			if let current = merged[dto.id], current.contentRevision > incoming.contentRevision {
				continue
			}
			merged[dto.id] = incoming
		}
		for id in Defaults[.receivedTombstoneIDs] {
			merged.removeValue(forKey: id)
		}
		Defaults[.receivedTimetables] = merged.values.sorted { $0.receivedAt < $1.receivedAt }
		applyLocalNames()
		Task { await SpotlightIndexer.shared.indexReceivedTimetables() }
		Defaults[.lastServerSync] = Date.now
		WidgetCenter.shared.reloadAllTimelines()
	}

	private func applyLocalNames() {
		WidgetCenter.shared.reloadAllTimelines()
	}

	private func requestFor(timetable: ReceivedPassMirrorDTO, walletRevision: Int) -> ReceivedProjectionUpdateRequest {
		ReceivedProjectionUpdateRequest(timetables: [timetable], walletRevision: walletRevision)
	}
}

private extension Endpoint {
	static let v1ReceivedTimetables = Endpoint("/v1/timetables/received")
	static let v1ReceivedNameOverrides = Endpoint("/v1/received-name-overrides")

	static func v1ReceivedNameOverride(_ serialNumber: String) -> Endpoint {
		Endpoint("/v1/received-name-overrides/\(serialNumber)", method: .put)
	}

	static func v1ReceivedNameOverrideDelete(_ serialNumber: String) -> Endpoint {
		Endpoint("/v1/received-name-overrides/\(serialNumber)", method: .delete)
	}

	static func v1ReceivedTimetableDelete(_ serialNumber: String) -> Endpoint {
		Endpoint("/v1/timetables/received/\(serialNumber)", method: .delete)
	}

	static func v1ReceivedTimetableUpdate(_ serialNumber: String) -> Endpoint {
		Endpoint("/v1/timetables/received/\(serialNumber)", method: .put)
	}
}
