//
//   OwnerTimetableSyncService.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class OwnerTimetableSyncService {
	static let shared = OwnerTimetableSyncService(networkManager: .shared)

	private(set) var isSyncing = false

	private let networkManager: NetworkManager
	private var currentOperation: (kind: OperationKind, generation: Int, task: Task<Void, any Error>)?
	private var operationGeneration = 0

	private enum OperationKind {
		case download
		case reconcile
		case upload
	}

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func uploadOwnerTimetable() async throws {
		try await run(.upload) { [self] in
			try await performUpload()
		}
	}

	func downloadOwnerTimetable() async throws {
		try await run(.download) { [self] in
			try await performDownload()
		}
	}

	func reconcileOwnerTimetable() async throws {
		try await run(.reconcile) { [self] in
			try await performReconciliation()
		}
	}

	private func run(
		_ kind: OperationKind,
		operation: @escaping @MainActor () async throws -> Void
	) async throws {
		if let currentOperation {
			if currentOperation.kind == kind {
				try await currentOperation.task.value
				return
			}

			_ = try? await currentOperation.task.value
			if self.currentOperation?.generation == currentOperation.generation {
				self.currentOperation = nil
				isSyncing = false
			}
			try await run(kind, operation: operation)
			return
		}

		operationGeneration += 1
		let generation = operationGeneration
		let task = Task { @MainActor in
			try Task.checkCancellation()
			try await operation()
		}
		currentOperation = (kind, generation, task)
		isSyncing = true
		defer {
			if currentOperation?.generation == generation {
				currentOperation = nil
				isSyncing = false
			}
		}
		try await task.value
	}

	private func performUpload() async throws {
		let clock = ContinuousClock()
		let start = clock.now
		let current: OwnerTimetableResponse = try await networkManager.send(.v1OwnerTimetable)
		let response: OwnerTimetableResponse = try await networkManager.send(
			.v1OwnerTimetableUpdate,
			body: OwnerTimetableUpdateRequest(
				subjects: Defaults[.timetable],
				expectedRevision: current.revision,
				isSearchable: Defaults[.ownerIsSearchable]
			)
		)
		Defaults[.lastServerSync] = Date.now
		Print(
			"Uploaded owner timetable revision \(response.revision)",
			category: .network,
			duration: start.duration(to: clock.now)
		)
	}

	private func performDownload() async throws {
		let clock = ContinuousClock()
		let start = clock.now
		let response: OwnerTimetableResponse = try await networkManager.send(.v1OwnerTimetable)
		Defaults[.timetable] = response.subjects
		Defaults[.ownerIsSearchable] = response.isSearchable
		Defaults[.lastServerSync] = Date.now
		Print(
			"Downloaded owner timetable revision \(response.revision)",
			category: .network,
			duration: start.duration(to: clock.now)
		)
	}

	private func performReconciliation() async throws {
		let response: OwnerTimetableResponse = try await networkManager.send(.v1OwnerTimetable)
		let localTimetable = Defaults[.timetable]
		let lastServerSync = Defaults[.lastServerSync]
		let serverIsNewer = response.updatedAt.map { updatedAt in
			guard let lastServerSync else { return true }
			return updatedAt > lastServerSync
		} ?? false

		if localTimetable.isEmpty || serverIsNewer {
			Defaults[.timetable] = response.subjects
			Defaults[.ownerIsSearchable] = response.isSearchable
			Defaults[.lastServerSync] = Date.now
			return
		}

		let updated: OwnerTimetableResponse = try await networkManager.send(
			.v1OwnerTimetableUpdate,
			body: OwnerTimetableUpdateRequest(
				subjects: localTimetable,
				expectedRevision: response.revision,
				isSearchable: Defaults[.ownerIsSearchable]
			)
		)
		Defaults[.lastServerSync] = Date.now
		Print("Reconciled owner timetable revision \(updated.revision)", category: .network)
	}
}

private extension Endpoint {
	static let v1OwnerTimetable = Endpoint("/v1/timetables/owner")
	static let v1OwnerTimetableUpdate = Endpoint("/v1/timetables/owner", method: .put)
}
