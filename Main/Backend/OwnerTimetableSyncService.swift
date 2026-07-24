//
//   OwnerTimetableSyncService.swift
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
final class OwnerTimetableSyncService {
	static let shared = OwnerTimetableSyncService(networkManager: .shared)

	private(set) var isSyncing = false

	private let networkManager: NetworkManager
	private var currentOperation: CurrentOperation?
	private var operationGeneration = 0
	private var pendingVisibility: Bool?
	private var visibilityTask: Task<Void, any Error>?

	private enum OperationKind {
		case download
		case reconcile
		case upload
	}

	private struct ErasedOperationResult: @unchecked Sendable {
		let value: Any
	}

	private struct CurrentOperation {
		let kind: OperationKind
		let generation: Int
		let task: Task<ErasedOperationResult, any Error>
	}

	private enum OperationRunError: LocalizedError {
		case mismatchedResult(OperationKind)

		var errorDescription: String? {
			switch self {
				case let .mismatchedResult(kind):
					"Sync operation \(kind) returned an unexpected result type."
			}
		}
	}

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func uploadOwnerTimetable(subjects: [Subject]? = nil) async throws {
		try Platform.require(Platform.current.allowsOwnerMutation)
		_ = try await uploadOwnerTimetableResponse(subjects: subjects)
	}

	func uploadOwnerTimetableResponse(subjects: [Subject]? = nil) async throws -> OwnerTimetableResponse {
		try Platform.require(Platform.current.allowsOwnerMutation)
		let response: OwnerTimetableResponse = try await run(.upload) { [self] in
			try await performUpload(subjects: subjects)
		}
		cacheID(response.id)
		return response
	}

	func downloadOwnerTimetable() async throws {
		try await run(.download) { [self] in
			try await performDownload()
		}
	}

	private func cacheID(_ id: UUID?) {
		if let id {
			Defaults[.ownerTimetableID] = id.uuidString
		}
	}

	func reconcileOwnerTimetable() async throws {
		try await run(.reconcile) { [self] in
			try await performReconciliation()
		}
	}

	@discardableResult
	func updateVisibility(_ isSearchable: Bool) async throws -> Bool {
		try Platform.require(Platform.current.allowsOwnerMutation)
		pendingVisibility = isSearchable

		if let visibilityTask {
			try await visibilityTask.value
			return Defaults[.ownerIsSearchable]
		}

		let task = Task { @MainActor in
			while let proposed = pendingVisibility {
				try Task.checkCancellation()
				pendingVisibility = nil

				let response: OwnerTimetableResponse = try await networkManager.send(
					.v1OwnerTimetableVisibility,
					body: OwnerTimetableVisibilityUpdateRequest(isSearchable: proposed)
				)

				Defaults[.ownerIsSearchable] = response.isSearchable
				Defaults[.lastServerSync] = Date.now
			}
		}

		visibilityTask = task
		defer { visibilityTask = nil }

		do {
			try await task.value
		} catch {
			pendingVisibility = nil
			throw error
		}

		return Defaults[.ownerIsSearchable]
	}

	@discardableResult
	private func run<T>(
		_ kind: OperationKind,
		operation: @escaping @MainActor () async throws -> T
	) async throws -> T {
		if let currentOperation {
			if currentOperation.kind == kind {
				let task = currentOperation.task

				let result = try await withTaskCancellationHandler {
					try await task.value
				} onCancel: {
					task.cancel()
				}

				if T.self == Void.self {
					return () as! T
				}

				guard let value = result.value as? T else {
					throw OperationRunError.mismatchedResult(kind)
				}

				return value
			}

			_ = try? await currentOperation.task.value

			if self.currentOperation?.generation == currentOperation.generation {
				self.currentOperation = nil
				isSyncing = false
			}

			return try await run(kind, operation: operation)
		}

		operationGeneration += 1
		let generation = operationGeneration

		let task = Task { @MainActor in
			try Task.checkCancellation()
			let value = try await operation()
			return ErasedOperationResult(value: value)
		}

		currentOperation = CurrentOperation(
			kind: kind,
			generation: generation,
			task: task
		)

		isSyncing = true

		defer {
			if currentOperation?.generation == generation {
				currentOperation = nil
				isSyncing = false
			}
		}

		let result = try await withTaskCancellationHandler {
			try await task.value
		} onCancel: {
			task.cancel()
		}

		if T.self == Void.self {
			return () as! T
		}

		guard let value = result.value as? T else {
			throw OperationRunError.mismatchedResult(kind)
		}

		return value
	}

	private func performUpload(subjects: [Subject]?) async throws -> OwnerTimetableResponse {
		let subjects = subjects ?? Defaults[.timetable]

		let response: OwnerTimetableResponse = try await networkManager.send(
			.v1OwnerTimetableUpdate,
			body: OwnerTimetableUpdateRequest(
				subjects: subjects,
				expectedRevision: nil,
				isSearchable: Defaults[.ownerIsSearchable]
			)
		)

		cache(response)

		Print("Uploaded owner timetable revision \(response.revision)", category: .network)

		return response
	}

	private func performDownload() async throws {
		let clock = ContinuousClock()
		let start = clock.now

		let response: OwnerTimetableResponse = try await networkManager.send(.v1OwnerTimetable)

		cache(response)

		Print(
			"Downloaded owner timetable revision \(response.revision)",
			category: .network,
			duration: start.duration(to: clock.now)
		)
	}

	private func performReconciliation() async throws {
		let response: OwnerTimetableResponse = try await networkManager.send(.v1OwnerTimetable)
		cacheID(response.id)

		let localTimetable = Defaults[.timetable]

		// Once the server has timetable content it is authoritative for every
		// device. A non-empty local timetable only seeds a freshly empty server.
		if localTimetable.isEmpty || !response.subjects.isEmpty {
			cache(response)
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

		cache(updated)

		Print("Reconciled owner timetable revision \(updated.revision)", category: .network)
	}

	private func cache(_ response: OwnerTimetableResponse) {
		Defaults[.timetable] = response.subjects
		Defaults[.ownerIsSearchable] = response.isSearchable
		cacheID(response.id)
		Defaults[.lastServerSync] = Date.now
		Task { await SpotlightIndexer.shared.indexOwnerTimetable() }
		WidgetCenter.shared.reloadAllTimelines()
	}
}

private extension Endpoint {
	static let v1OwnerTimetable = Endpoint("/v1/timetables/owner")
	static let v1OwnerTimetableUpdate = Endpoint("/v1/timetables/owner", method: .put)
	static let v1OwnerTimetableVisibility = Endpoint("/v1/timetables/owner/visibility", method: .put)
}
