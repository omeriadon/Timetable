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

	func updateUserAuthority(id: UUID, authority: AccountAuthority) async throws -> AdministrationUserResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/users/\(id.uuidString)/authority", method: .put),
			body: AdministrationUserAuthorityUpdateRequest(authority: authority),
			context: .userInitiated
		)
	}

	func serverAccessMode(controlToken: String) async throws -> ServerAccessModeResponse {
		try await networkManager.send(
			serverAccessModeEndpoint(method: .get, controlToken: controlToken),
			context: .userInitiated
		)
	}

	func updateServerAccessMode(
		developmentAccessOnly: Bool,
		controlToken: String
	) async throws -> ServerAccessModeResponse {
		try await networkManager.send(
			serverAccessModeEndpoint(method: .put, controlToken: controlToken),
			body: ServerAccessModeUpdateRequest(developmentAccessOnly: developmentAccessOnly),
			context: .userInitiated
		)
	}

	func createUser(request: AdministrationUserCreateRequest) async throws -> AdministrationUserResponse {
		try await networkManager.send(.v1AdministrationUsersCreate, body: request, context: .userInitiated)
	}

	func deleteUser(id: UUID) async throws {
		try await networkManager.send(Endpoint("/v1/administration/users/\(id.uuidString)", method: .delete), context: .userInitiated)
	}

	func userDetail(id: UUID) async throws -> AdministrationUserDetailResponse {
		try await networkManager.send(Endpoint("/v1/administration/users/\(id.uuidString)"), context: .userInitiated)
	}

	func broadcastNotification(_ request: BroadcastNotificationRequest) async throws -> BroadcastNotificationResponse {
		try await networkManager.send(.v1AdministrationBroadcastNotification, body: request, context: .userInitiated)
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

	private func serverAccessModeEndpoint(method: HTTPMethod, controlToken: String) -> Endpoint {
		Endpoint(
			"/_operations/server-access-mode",
			method: method,
			requiresAuthentication: false,
			headers: ["X-PMSTT-Access-Mode-Token": controlToken]
		)
	}
}

private extension Endpoint {
	static let v1Administration = Endpoint("/v1/administration")
	static let v1AdministrationUsers = Endpoint("/v1/administration/users")
	static let v1AdministrationUsersCreate = Endpoint("/v1/administration/users", method: .post)
	static let v1AdministrationCalendar = Endpoint("/v1/administration/calendar")
	static let v1AdministrationCalendarCreate = Endpoint("/v1/administration/calendar", method: .post)
	static let v1AdministrationBroadcastNotification = Endpoint("/v1/administration/broadcast-notification", method: .post)
}
