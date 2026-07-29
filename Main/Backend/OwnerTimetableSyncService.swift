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

	private enum RecordSyncError: LocalizedError {
		case missingResult
		case rejected(String)

		var errorDescription: String? {
			switch self {
				case .missingResult:
					"The server returned an incomplete synchronization response."
				case let .rejected(message):
					message
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
				setOwnerTimetableRevision(response.revision)
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
		let recordID = UUID(uuidString: Defaults[.ownerTimetableID])
		let mutation = SyncRecordMutation(
			mutationID: UUID(),
			recordType: .ownerTimetable,
			recordID: recordID,
			operation: .upsert,
			baseRevision: Defaults[.syncRecordRevisions].revision(
				for: .ownerTimetable,
				recordID: nil
			),
			ownerTimetable: OwnerTimetableSyncPayload(
				subjects: subjects,
				isSearchable: Defaults[.ownerIsSearchable]
			)
		)
		var pendingMutations = Defaults[.pendingSyncMutations]
		pendingMutations.append(mutation)
		Defaults[.pendingSyncMutations] = pendingMutations

		let responses = try await flushPendingMutations()
		guard let response = responses[mutation.mutationID] else {
			throw RecordSyncError.missingResult
		}

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
		_ = try await flushPendingMutations()

		let response: OwnerTimetableResponse = try await networkManager.send(.v1OwnerTimetable)
		cacheID(response.id)
		setOwnerTimetableRevision(response.revision)

		let localTimetable = Defaults[.timetable]

		// Once the server has timetable content it is authoritative for every
		// device. A non-empty local timetable only seeds a freshly empty server.
		if localTimetable.isEmpty || !response.subjects.isEmpty {
			cache(response)
			return
		}

		let updated = try await performUpload(subjects: localTimetable)

		Print("Reconciled owner timetable revision \(updated.revision)", category: .network)
	}

	private func flushPendingMutations() async throws -> [UUID: OwnerTimetableResponse] {
		var responses: [UUID: OwnerTimetableResponse] = [:]
		var hasPolledServer = false

		while !hasPolledServer || !Defaults[.pendingSyncMutations].isEmpty {
			let mutation = Defaults[.pendingSyncMutations].first
			let envelope = SyncEnvelopeRequest(
				requestID: UUID(),
				installationID: ClientIdentityProvider.shared.identity().installationID,
				mutations: mutation.map { [$0] } ?? [],
				cursor: Defaults[.syncCursor]
			)
			let response: SyncEnvelopeResponse = try await networkManager.send(
				.v1RecordSync,
				body: envelope
			)
			hasPolledServer = true

			apply(response.tombstones)
			if let nextCursor = response.nextCursor {
				Defaults[.syncCursor] = nextCursor
			}

			guard let mutation else {
				continue
			}
			guard let result = response.results.first(
				where: { $0.mutationID == mutation.mutationID }
			) else {
				throw RecordSyncError.missingResult
			}

			if let ownerTimetable = result.ownerTimetable {
				cache(ownerTimetable)
				setOwnerTimetableRevision(result.serverRevision)
				responses[mutation.mutationID] = ownerTimetable
			}

			switch result.outcome {
				case .accepted, .invalidReferenceDropped, .serverRecordNewer:
					removePendingMutation(mutation.mutationID)
				case .deletedOnServer:
					removePendingMutation(mutation.mutationID)
					Defaults[.timetable] = []
					setOwnerTimetableRevision(result.serverRevision)
				case .authorizationRejected, .validationRejected:
					removePendingMutation(mutation.mutationID)
					throw RecordSyncError.rejected(
						result.message ?? "The server rejected the timetable change."
					)
			}
		}

		Defaults[.lastServerSync] = .now
		return responses
	}

	private func apply(_ tombstones: [SyncTombstone]) {
		guard !tombstones.isEmpty else {
			return
		}

		var storedTombstones = Defaults[.syncTombstones]
		var revisions = Defaults[.syncRecordRevisions]
		var removedOwnerTimetable = false

		for tombstone in tombstones {
			guard tombstone.revision > revisions.revision(
				for: tombstone.recordType,
				recordID: nil
			) else {
				continue
			}

			switch tombstone.recordType {
				case .ownerTimetable:
					let cachedRecordID = UUID(
						uuidString: Defaults[.ownerTimetableID]
					)
					guard cachedRecordID == nil ||
						cachedRecordID == tombstone.recordID
					else {
						continue
					}

					Defaults[.timetable] = []
					Defaults[.ownerTimetableID] = ""
					removedOwnerTimetable = true
			}

			revisions.setRevision(
				tombstone.revision,
				for: tombstone.recordType,
				recordID: nil
			)
			storedTombstones.removeAll {
				$0.recordType == tombstone.recordType &&
					$0.recordID == tombstone.recordID
			}
			storedTombstones.append(tombstone)
		}

		let retentionCutoff = Date.now.addingTimeInterval(-90 * 24 * 60 * 60)
		storedTombstones.removeAll {
			$0.deletedAt < retentionCutoff
		}
		Defaults[.syncTombstones] = storedTombstones
		Defaults[.syncRecordRevisions] = revisions

		if removedOwnerTimetable {
			Task {
				await SpotlightIndexer.shared.indexOwnerTimetable()
			}
			WidgetCenter.shared.reloadAllTimelines()
		}
	}

	private func removePendingMutation(_ mutationID: UUID) {
		var pendingMutations = Defaults[.pendingSyncMutations]
		pendingMutations.removeAll {
			$0.mutationID == mutationID
		}
		Defaults[.pendingSyncMutations] = pendingMutations
	}

	private func setOwnerTimetableRevision(_ revision: Int) {
		var revisions = Defaults[.syncRecordRevisions]
		revisions.setRevision(
			revision,
			for: .ownerTimetable,
			recordID: nil
		)
		Defaults[.syncRecordRevisions] = revisions
	}

	private func cache(_ response: OwnerTimetableResponse) {
		Defaults[.timetable] = response.subjects
		Defaults[.ownerIsSearchable] = response.isSearchable
		cacheID(response.id)
		setOwnerTimetableRevision(response.revision)
		Defaults[.lastServerSync] = Date.now
		Task { await SpotlightIndexer.shared.indexOwnerTimetable() }
		WidgetCenter.shared.reloadAllTimelines()
	}
}

private extension Endpoint {
	static let v1RecordSync = Endpoint("/v1/sync", method: .post)
	static let v1OwnerTimetable = Endpoint("/v1/timetables/owner")
	static let v1OwnerTimetableUpdate = Endpoint("/v1/timetables/owner", method: .put)
	static let v1OwnerTimetableVisibility = Endpoint("/v1/timetables/owner/visibility", method: .put)
}
