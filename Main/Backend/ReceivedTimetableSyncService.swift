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

	func downloadProjectionAndOverrides() async throws {
		try await refreshAuthoritativeProjection()
	}

	func refreshAuthoritativeProjection() async throws {
		if let syncTask {
			try await syncTask.value
			return
		}

		let task = Task { @MainActor in
			var offset = 0
			var projection: [AuthoritativeReceivedTimetableDTO] = []
			while true {
				let page: [AuthoritativeReceivedTimetableDTO] = try await networkManager.send(.v1AuthoritativeReceived(offset: offset))
				projection.append(contentsOf: page)
				guard page.count == 50 else { break }
				offset += page.count
			}
			apply(projection)
		}
		syncTask = task
		isSyncing = true
		defer {
			syncTask = nil
			isSyncing = false
		}
		try await task.value
	}

	@discardableResult
	func importTimetable(id: UUID) async throws -> ReceivedTimetable {
		try await importTimetable(locator: id.uuidString)
	}

	@discardableResult
	func importTimetable(locator: String) async throws -> ReceivedTimetable {
		try Platform.require(Platform.current.allowsReceivedTimetableMutation)
		let response: AuthoritativeReceivedTimetableDTO = try await networkManager.send(
			.v1ReceivedImport,
			body: UUID(uuidString: locator).map { ReceivedTimetableImportRequest(timetableID: $0) } ?? ReceivedTimetableImportRequest(timetableLocator: locator),
			context: .userInitiated
		)
		try await refreshAuthoritativeProjection()
		return response.receivedTimetable
	}

	func deleteReceivedTimetable(serialNumber: String) async throws {
		try Platform.require(Platform.current.allowsReceivedTimetableMutation)
		guard let timetable = Defaults[.receivedTimetables].first(where: { $0.id == serialNumber }),
		      let importID = timetable.importID
		else { return }
		try await networkManager.send(.v1ReceivedImportDelete(importID), context: .userInitiated)
		try await refreshAuthoritativeProjection()
	}

	private func apply(_ response: [AuthoritativeReceivedTimetableDTO]) {
		Defaults[.receivedTimetables] = response
			.filter { $0.availability == .available }
			.map(\.receivedTimetable)
			.sorted { $0.receivedAt < $1.receivedAt }
		Task { await SpotlightIndexer.shared.indexReceivedTimetables() }
		Defaults[.lastServerSync] = .now
		WidgetCenter.shared.reloadAllTimelines()
	}
}

private extension Endpoint {
	static func v1AuthoritativeReceived(offset: Int) -> Endpoint {
		Endpoint("/v1/timetables/received/authoritative", queryItems: [
			URLQueryItem(name: "limit", value: "50"),
			URLQueryItem(name: "offset", value: String(offset)),
		])
	}

	static let v1ReceivedImport = Endpoint("/v1/timetables/received/import", method: .post)

	static func v1ReceivedImportDelete(_ importID: String) -> Endpoint {
		Endpoint("/v1/timetables/received/authoritative/\(importID)", method: .delete)
	}
}
