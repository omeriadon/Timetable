import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TimetableDiscoveryService {
	static let shared = TimetableDiscoveryService()

	private(set) var results: [TimetableSearchResult] = []
	private(set) var isSearching = false
	private var task: Task<Void, Never>?
	private let network = NetworkManager.shared

	func search(_ rawQuery: String, immediately: Bool = false) {
		task?.cancel()
		let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
		guard (3 ..< 50).contains(query.count) else {
			withAnimation(.snappy) { results = [] }
			isSearching = false
			return
		}
		task = Task {
			if !immediately {
				try? await Task.sleep(for: .milliseconds(250))
			}
			guard !Task.isCancelled else { return }
			isSearching = true
			defer { isSearching = false }
			do {
				let response: [TimetableSearchResult] = try await network.send(.timetableSearch(query))
				guard !Task.isCancelled else { return }
				withAnimation(.snappy) { results = response }
			} catch is CancellationError {} catch {
				if !Task.isCancelled {
					results = []
				}
			}
		}
	}

	func detail(id: UUID) async throws -> TimetableDetailResponse {
		try await network.send(Endpoint("/v1/timetables/\(id.uuidString)"))
	}

	func report(authorID: UUID) async throws {
		try await network.send(Endpoint("/v1/report/user", method: .post), body: ReportUserRequest(reportedAccountID: authorID.uuidString))
	}
}

private extension Endpoint {
	static func timetableSearch(_ query: String) -> Endpoint {
		Endpoint("/v1/timetables/search", queryItems: [URLQueryItem(name: "q", value: query)])
	}
}
