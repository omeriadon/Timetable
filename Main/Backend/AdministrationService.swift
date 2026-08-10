import Defaults
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
		let response: EventTagCatalogueResponse = try await networkManager.send(.v1Tags)
		Defaults[.eventTagCatalogue] = response
		return response
	}

	func tagSubscriptions() async throws -> EventTagSubscriptionResponse {
		let response: EventTagSubscriptionResponse = try await networkManager.send(.v1TagSubscriptions)
		Defaults[.eventTagSubscriptionIDs] = response.tagIDs
		return response
	}

	func replaceTagSubscriptions(_ tagIDs: Set<UUID>) async throws -> EventTagSubscriptionResponse {
		let response: EventTagSubscriptionResponse = try await networkManager.send(
			.v1TagSubscriptionsUpdate,
			body: EventTagSubscriptionUpdateRequest(tagIDs: Array(tagIDs)),
			context: .userInitiated
		)
		Defaults[.eventTagSubscriptionIDs] = response.tagIDs
		return response
	}

	func replaceSubjectTagSubscriptions(_ tagIDs: Set<UUID>) async throws -> EventTagSubscriptionResponse {
		try await networkManager.send(
			.v1SubjectTagSubscriptionsUpdate,
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

	func serverAccessMode() async throws -> ServerAccessModeResponse {
		try await networkManager.send(
			.v1AdministrationServerAccessModeGet,
			context: .userInitiated
		)
	}

	func updateServerAccessMode(
		developmentAccessOnly: Bool
	) async throws -> ServerAccessModeResponse {
		try await networkManager.send(
			.v1AdministrationServerAccessModeUpdate,
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

	func friendshipDateChangeRequests() async throws -> [AdministrationFriendshipDateChangeRequest] {
		try await networkManager.send(Endpoint("/v1/administration/friends-since-requests"))
	}

	func resolveFriendshipDateChangeRequest(
		id: UUID,
		action: ModerationAction
	) async throws -> AdministrationFriendshipDateChangeRequest {
		try await networkManager.send(
			Endpoint("/v1/administration/friends-since-requests/\(id.uuidString)", method: .put),
			body: AdministrationModerationResolutionRequest(action: action),
			context: .userInitiated
		)
	}

	func userReports() async throws -> [AdministrationUserReport] {
		try await networkManager.send(Endpoint("/v1/administration/user-reports"))
	}

	func resolveUserReport(id: UUID, action: ModerationAction) async throws -> AdministrationUserReport {
		try await networkManager.send(
			Endpoint("/v1/administration/user-reports/\(id.uuidString)", method: .put),
			body: AdministrationModerationResolutionRequest(action: action),
			context: .userInitiated
		)
	}

	func broadcastNotification(_ request: BroadcastNotificationRequest) async throws -> BroadcastNotificationResponse {
		try await networkManager.send(.v1AdministrationBroadcastNotification, body: request, context: .userInitiated)
	}

	func broadcastNotifications() async throws -> [BroadcastNotificationHistoryResponse] {
		try await networkManager.send(.v1AdministrationBroadcastNotifications)
	}

	func deleteBroadcastNotification(id: UUID) async throws -> BroadcastNotificationHistoryResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/broadcast-notifications/\(id.uuidString)", method: .delete),
			context: .userInitiated
		)
	}

	func profileStorageQuota() async throws -> ProfileStorageQuotaResponse {
		try await networkManager.send(.v1AdministrationProfileStorageQuota)
	}

	func specialBadges() async throws -> [AdministrationSpecialBadgeResponse] {
		try await networkManager.send(.v1AdministrationSpecialBadges)
	}

	func createSpecialBadge(
		_ request: AdministrationSpecialBadgeRequest
	) async throws -> AdministrationSpecialBadgeResponse {
		try await networkManager.send(
			.v1AdministrationSpecialBadgesCreate,
			body: request,
			context: .userInitiated
		)
	}

	func reorderSpecialBadges(
		badgeIDs: [UUID]
	) async throws -> [AdministrationSpecialBadgeResponse] {
		try await networkManager.send(
			.v1AdministrationSpecialBadgesOrder,
			body: AdministrationSpecialBadgeOrderRequest(badgeIDs: badgeIDs),
			context: .userInitiated
		)
	}

	@discardableResult
	func updateSpecialBadge(
		id: UUID,
		request: AdministrationSpecialBadgeRequest
	) async throws -> AdministrationSpecialBadgeResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/badges/\(id.uuidString)", method: .put),
			body: request,
			context: .userInitiated
		)
	}

	func replaceSpecialBadgeUsers(
		id: UUID,
		userIDs: Set<UUID>
	) async throws -> AdministrationSpecialBadgeResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/badges/\(id.uuidString)/users", method: .put),
			body: AdministrationSpecialBadgeAssignmentsRequest(userIDs: Array(userIDs)),
			context: .userInitiated
		)
	}

	func deleteSpecialBadge(id: UUID) async throws {
		try await networkManager.send(
			Endpoint("/v1/administration/badges/\(id.uuidString)", method: .delete),
			context: .userInitiated
		)
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

	func deleteEventTag(id: UUID) async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(
			Endpoint("/v1/administration/event-tags/\(id.uuidString)", method: .delete),
			context: .userInitiated
		)
	}

	func reorderEventTags(
		tagIDs: [UUID]
	) async throws -> AdministrationEventTagCatalogueResponse {
		try await networkManager.send(
			.v1AdministrationEventTagsOrder,
			body: AdministrationEventTagOrderRequest(tagIDs: tagIDs),
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
}

private extension Endpoint {
	static let v1Administration = Endpoint("/v1/administration")
	static let v1AdministrationUsers = Endpoint("/v1/administration/users")
	static let v1AdministrationUsersCreate = Endpoint("/v1/administration/users", method: .post)
	static let v1AdministrationCalendar = Endpoint("/v1/administration/calendar")
	static let v1AdministrationCalendarCreate = Endpoint("/v1/administration/calendar", method: .post)
	static let v1AdministrationBroadcastNotification = Endpoint("/v1/administration/broadcast-notification", method: .post)
	static let v1AdministrationBroadcastNotifications = Endpoint("/v1/administration/broadcast-notifications")
	static let v1AdministrationProfileStorageQuota = Endpoint("/v1/administration/profile-storage-quota")
	static let v1AdministrationSpecialBadges = Endpoint("/v1/administration/badges")
	static let v1AdministrationSpecialBadgesCreate = Endpoint("/v1/administration/badges", method: .post)
	static let v1AdministrationSpecialBadgesOrder = Endpoint("/v1/administration/badges/order", method: .put)
	static let v1AdministrationServerAccessModeGet = Endpoint("/_operations/server-access-mode")
	static let v1AdministrationServerAccessModeUpdate = Endpoint("/_operations/server-access-mode", method: .put)
	static let v1AdministrationEventTags = Endpoint("/v1/administration/event-tags")
	static let v1AdministrationEventTagsCreate = Endpoint("/v1/administration/event-tags", method: .post)
	static let v1AdministrationEventTagsOrder = Endpoint("/v1/administration/event-tags/order", method: .put)
	static let v1AdministrationEventTagSectionsCreate = Endpoint("/v1/administration/event-tags/sections", method: .post)
	static let v1Tags = Endpoint("/v1/tags")
	static let v1TagSubscriptions = Endpoint("/v1/tags/subscriptions")
	static let v1TagSubscriptionsUpdate = Endpoint("/v1/tags/subscriptions", method: .put)
	static let v1SubjectTagSubscriptionsUpdate = Endpoint("/v1/tags/subscriptions/subjects", method: .put)
}
