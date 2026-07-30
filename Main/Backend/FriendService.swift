import Defaults
import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class FriendService {
	static let shared = FriendService(networkManager: .shared)

	private let networkManager: NetworkManager
	private(set) var isRefreshing = false
	private var refreshTask: Task<Void, any Error>?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func refresh() async throws {
		if let refreshTask {
			try await refreshTask.value
			return
		}

		let task = Task<Void, any Error> { @MainActor in
			async let friends: [FriendSummary] = networkManager.send(.v1Friends)
			async let requests: [FriendSummary] = networkManager.send(.v1IncomingFriendRequests)
			async let profile: FriendProfile = networkManager.send(.v1FriendProfile)
			let result = try await (friends, requests, profile)
			Defaults[.friends] = result.0
			Defaults[.incomingFriendRequests] = result.1
			if let appearance = result.2.appearance {
				Defaults[.profileAppearance] = appearance
			} else if let appearanceData = result.2.appearanceData,
			          let appearance = try? JSONDecoder().decode(ProfileAppearance.self, from: appearanceData)
			{
				Defaults[.profileAppearance] = appearance
			}
			await cacheWidgetProfilePhotos(
				profile: result.2,
				friends: result.0
			)
			Defaults[.lastServerSync] = .now
			WidgetCenter.shared.reloadAllTimelines()
		}
		refreshTask = task
		isRefreshing = true
		defer {
			refreshTask = nil
			isRefreshing = false
		}
		try await task.value
	}

	func search(schoolEmail: String) async throws -> [FriendSearchResult] {
		try await networkManager.send(.v1FriendSearch(schoolEmail: schoolEmail), context: .userInitiated)
	}

	func sendRequest(to schoolEmail: String) async throws -> FriendSummary {
		let result: FriendSummary = try await networkManager.send(
			.v1FriendRequests,
			body: CreateFriendRequest(schoolEmail: schoolEmail),
			context: .userInitiated
		)
		try await refresh()
		return result
	}

	func accept(_ request: FriendSummary) async throws {
		let _: FriendSummary = try await networkManager.send(
			.v1AcceptFriendRequest(request.relationshipID),
			context: .userInitiated
		)
		try await refresh()
	}

	func detail(for friendID: UUID) async throws -> FriendDetail {
		try await networkManager.send(.v1Friend(friendID), context: .userInitiated)
	}

	func remove(friendID: UUID) async throws {
		try await networkManager.send(.v1Friend(friendID, method: .delete), context: .userInitiated)
		try await refresh()
	}

	func block(friendID: UUID) async throws {
		try await networkManager.send(.v1BlockFriend(friendID), context: .userInitiated)
		try await refresh()
	}

	func reorder(friendIDs: [UUID]) async throws {
		let orderedFriends: [FriendSummary] = try await networkManager.send(
			.v1FriendOrder,
			body: FriendOrderUpdateRequest(friendIDs: friendIDs),
			context: .userInitiated
		)
		Defaults[.friends] = orderedFriends
		WidgetCenter.shared.reloadAllTimelines()
	}

	func updateProfileAppearance(_ appearance: ProfileAppearance) async throws {
		let profile: FriendProfile = try await networkManager.send(
			.v1FriendProfileUpdate,
			body: FriendProfileAppearanceUpdateRequest(
				appearance: appearance,
				baseRevision: Defaults[.accountProfile]?.revision ?? 0
			),
			context: .userInitiated
		)
		Defaults[.profileAppearance] = profile.appearance ?? appearance
		_ = try await SessionStore.shared.refreshProfile()
		WidgetCenter.shared.reloadAllTimelines()
	}

	func saveProfile(_ draft: ProfileAppearanceDraft) async throws -> AccountProfile {
		if draft.displayName != Defaults[.accountProfile]?.displayName {
			_ = try await SessionStore.shared.updateProfile(displayName: draft.displayName)
		}

		if let pendingPhotoData = draft.pendingPhotoData {
			let _: FriendProfile = try await networkManager.upload(
				.v1FriendProfilePhoto,
				data: pendingPhotoData
			)
		}

		try await updateProfileAppearance(draft.appearance)

		if draft.removesPhoto {
			try await networkManager.send(.v1FriendProfilePhotoDelete, context: .userInitiated)
		}

		let profile = try await SessionStore.shared.refreshProfile()
		if let photo = profile.photo {
			_ = await ProfileImageCache.shared.imageData(
				for: photo,
				displaySize: 36
			)
		}
		try await refresh()
		return profile
	}

	private func cacheWidgetProfilePhotos(
		profile: FriendProfile,
		friends: [FriendSummary]
	) async {
		var metadata = friends.compactMap(\.friend.photo)
		if let photo = profile.photo {
			metadata.append(photo)
		}
		for photo in metadata {
			_ = await ProfileImageCache.shared.imageData(
				for: photo,
				displaySize: 36
			)
		}
	}
}

private extension Endpoint {
	static let v1Friends = Endpoint("/v1/friends")
	static let v1IncomingFriendRequests = Endpoint("/v1/friends/requests")
	static let v1FriendRequests = Endpoint("/v1/friends/requests", method: .post)
	static let v1FriendProfile = Endpoint("/v1/friends/profile")
	static let v1FriendProfileUpdate = Endpoint("/v1/friends/profile", method: .put)
	static let v1FriendProfilePhoto = Endpoint(
		"/v1/friends/profile/photo",
		method: .put,
		headers: ["Content-Type": "image/jpeg"]
	)
	static let v1FriendProfilePhotoDelete = Endpoint("/v1/friends/profile/photo", method: .delete)

	static func v1FriendSearch(schoolEmail: String) -> Endpoint {
		Endpoint("/v1/friends/search", queryItems: [URLQueryItem(name: "q", value: schoolEmail)])
	}

	static func v1AcceptFriendRequest(_ relationshipID: UUID) -> Endpoint {
		Endpoint("/v1/friends/requests/\(relationshipID.uuidString)/accept", method: .post)
	}

	static func v1Friend(_ friendID: UUID, method: HTTPMethod = .get) -> Endpoint {
		Endpoint("/v1/friends/\(friendID.uuidString)", method: method)
	}

	static func v1BlockFriend(_ friendID: UUID) -> Endpoint {
		Endpoint("/v1/friends/\(friendID.uuidString)/block", method: .post)
	}

	static let v1FriendOrder = Endpoint("/v1/friends/order", method: .put)
}
