import Foundation
import Observation

@MainActor
@Observable
final class TimetableDiscoveryService {
	static let shared = TimetableDiscoveryService()

	private let network = NetworkManager.shared

	func report(authorID: UUID) async throws {
		try Platform.require(Platform.current.allowsOwnerMutation)
		try await network.send(Endpoint("/v1/report/user", method: .post), body: ReportUserRequest(reportedAccountID: authorID.uuidString))
	}
}
