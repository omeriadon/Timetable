import Foundation

@MainActor
final class AdministrationService {
	static let shared = AdministrationService(networkManager: .shared)
	private let networkManager: NetworkManager
	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func dashboard() async throws -> AdministrationDashboardResponse {
		try await networkManager.send(.v1Administration)
	}

	func users() async throws -> [AdministrationUserResponse] {
		try await networkManager.send(.v1AdministrationUsers)
	}

	func updateUser(id: UUID, request: AdministrationUserUpdateRequest) async throws -> AdministrationUserResponse {
		try await networkManager.send(Endpoint("/v1/administration/users/\(id.uuidString)", method: .put), body: request, context: .userInitiated)
	}

	func calendar() async throws -> [AdministrationCalendarEntry] {
		try await networkManager.send(.v1AdministrationCalendar)
	}

	func save(_ request: AdministrationCalendarEntryRequest, id: UUID?) async throws -> [AdministrationCalendarEntry] {
		try await networkManager.send(id.map { Endpoint("/v1/administration/calendar/\($0.uuidString)", method: .put) } ?? .v1AdministrationCalendarCreate, body: request, context: .userInitiated)
	}

	func delete(id: UUID) async throws -> [AdministrationCalendarEntry] {
		try await networkManager.send(Endpoint("/v1/administration/calendar/\(id.uuidString)", method: .delete), context: .userInitiated)
	}
}

private extension Endpoint { static let v1Administration = Endpoint("/v1/administration"); static let v1AdministrationUsers = Endpoint("/v1/administration/users"); static let v1AdministrationCalendar = Endpoint("/v1/administration/calendar"); static let v1AdministrationCalendarCreate = Endpoint("/v1/administration/calendar", method: .post) }
