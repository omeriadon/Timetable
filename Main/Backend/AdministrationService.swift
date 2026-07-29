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

	func tagCatalogue() async throws -> EventTagCatalogueResponse {
		try await networkManager.send(.v1Tags)
	}

	func tagSubscriptions() async throws -> EventTagSubscriptionResponse {
		try await networkManager.send(.v1TagSubscriptions)
	}

	func replaceTagSubscriptions(_ tagIDs: Set<UUID>) async throws -> EventTagSubscriptionResponse {
		try await networkManager.send(
			.v1TagSubscriptionsUpdate,
			body: EventTagSubscriptionUpdateRequest(tagIDs: Array(tagIDs)),
			context: .userInitiated
		)
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

	func eventTags() async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(.v1AdministrationEventTags)
	}

	func createEventTag(
		_ request: AdministrationEventTagRequest
	) async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(
			.v1AdministrationEventTagsCreate,
			body: request,
			context: .userInitiated
		)
	}

	func updateEventTag(
		id: UUID,
		request: AdministrationEventTagRequest
	) async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/event-tags/\(id.uuidString)", method: .put),
			body: request,
			context: .userInitiated
		)
	}

	func createEventTagSection(
		_ request: AdministrationEventTagSectionCreateRequest
	) async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(
			.v1AdministrationEventTagSectionsCreate,
			body: request,
			context: .userInitiated
		)
	}

	func updateEventTagSection(
		id: UUID,
		request: AdministrationEventTagSectionUpdateRequest
	) async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/event-tags/sections/\(id.uuidString)", method: .put),
			body: request,
			context: .userInitiated
		)
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
	static let v1AdministrationEventTags = Endpoint("/v1/administration/event-tags")
	static let v1AdministrationEventTagsCreate = Endpoint("/v1/administration/event-tags", method: .post)
	static let v1AdministrationEventTagSectionsCreate = Endpoint("/v1/administration/event-tags/sections", method: .post)
	static let v1Tags = Endpoint("/v1/tags")
	static let v1TagSubscriptions = Endpoint("/v1/tags/subscriptions")
	static let v1TagSubscriptionsUpdate = Endpoint("/v1/tags/subscriptions", method: .put)
}
