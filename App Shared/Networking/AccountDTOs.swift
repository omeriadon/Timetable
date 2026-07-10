//
//   AccountDTOs.swift
//   App Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Foundation

nonisolated struct RegisterRequest: Codable {
	let email: String
	let password: String
	let displayName: String
}

nonisolated struct LoginRequest: Codable {
	let email: String
	let password: String
}

nonisolated struct RefreshRequest: Codable {
	let refreshToken: String
}

nonisolated struct LogoutRequest: Codable {
	let refreshToken: String
}

nonisolated struct AppleSignInRequest: Codable {
	let identityToken: String
	let displayName: String?
}

nonisolated struct TokenResponse: Codable {
	let accessToken: String
	let refreshToken: String
	let user: UserProfileResponse
}

nonisolated struct WatchSessionRequest: Codable {
	let installationID: String
}

nonisolated struct UserProfileResponse: Codable {
	let id: UUID
	let email: String?
	let displayName: String
	let createdAt: Date?
}

nonisolated struct UpdateProfileRequest: Codable {
	let displayName: String?
	let email: String?
}

nonisolated struct OwnerTimetableUpdateRequest: Codable {
	let subjects: [Subject]
	let expectedRevision: Int?
	var isSearchable: Bool? = nil
}

nonisolated struct OwnerTimetableVisibilityUpdateRequest: Codable {
	let isSearchable: Bool
}

nonisolated struct OwnerTimetableResponse: Codable {
	let subjects: [Subject]
	let revision: Int
	let updatedAt: Date?
	let isSearchable: Bool

	private enum CodingKeys: String, CodingKey { case subjects, revision, updatedAt, isSearchable }

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		subjects = try container.decode([Subject].self, forKey: .subjects)
		revision = try container.decode(Int.self, forKey: .revision)
		updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
		isSearchable = try container.decodeIfPresent(Bool.self, forKey: .isSearchable) ?? true
	}
}

nonisolated struct TimetableSearchResult: Codable, Identifiable, Hashable {
	let id: UUID
	let title: String
	let authorAccountID: UUID
	let authorDisplayName: String
	let sourceKind: SourceKind
	let confidence: Double
}

nonisolated struct TimetableDetailResponse: Codable, Identifiable, Hashable {
	let id: UUID
	let title: String
	let authorAccountID: UUID
	let authorDisplayName: String
	let sourceKind: SourceKind
	let subjects: [Subject]
	let subjectCount: Int
	let weeklyLessonCount: Int
	let updatedAt: Date?
	let activeInstallCount: Int
	let isSearchable: Bool
	let canEdit: Bool
}

nonisolated struct AuthoredTimetableUpdateRequest: Codable {
	let title: String
	let subjects: [Subject]
	let isSearchable: Bool
}

nonisolated struct ReportUserRequest: Codable {
	let reportedAccountID: String
}

nonisolated struct FeedbackRequest: Codable {
	let category: String
	let message: String
}

nonisolated struct ReceivedPassMirrorDTO: Codable {
	let id: String
	let issuerAccountID: String
	let sourceKind: SourceKind
	let signedDisplayName: String
	let authorDisplayName: String?
	let subjects: [Subject]
	let receivedAt: Date
	let passUpdatedAt: Date
	let contentRevision: Int
	let isDeleted: Bool
	let isShareable: Bool
	let walletRevision: Int

	init(_ timetable: ReceivedTimetable, walletRevision: Int) {
		id = timetable.id
		issuerAccountID = timetable.issuerAccountID
		sourceKind = timetable.sourceKind
		signedDisplayName = timetable.signedDisplayName
		authorDisplayName = timetable.authorDisplayName
		subjects = timetable.subjects
		receivedAt = timetable.receivedAt
		passUpdatedAt = timetable.passUpdatedAt
		contentRevision = timetable.contentRevision
		isDeleted = timetable.isDeleted
		isShareable = timetable.isShareable
		self.walletRevision = walletRevision
	}

	var receivedTimetable: ReceivedTimetable {
		ReceivedTimetable(
			id: id,
			issuerAccountID: issuerAccountID,
			sourceKind: sourceKind,
			signedDisplayName: signedDisplayName,
			authorDisplayName: authorDisplayName,
			subjects: subjects,
			receivedAt: receivedAt,
			passUpdatedAt: passUpdatedAt,
			contentRevision: contentRevision,
			isDeleted: isDeleted,
			isShareable: isShareable
		)
	}
}

nonisolated struct ReceivedProjectionUpdateRequest: Codable {
	let timetables: [ReceivedPassMirrorDTO]
	let walletRevision: Int
}

nonisolated struct ReceivedNameOverrideResponse: Codable {
	let serialNumber: String
	let displayName: String
}

nonisolated struct UpdateReceivedNameOverrideRequest: Codable {
	let displayName: String
}

nonisolated struct RegisterUserDeviceRequest: Codable {
	let installationID: String
	let platform: String
	let apnsToken: String
	/// `true` when the token is from a debug/sandbox build.
	let isDebug: Bool
}

nonisolated struct RemoveUserDeviceRequest: Codable {
	let installationID: String
}

nonisolated struct UserDeviceResponse: Codable {
	let installationID: String
	let platform: String
	let isDebug: Bool
	let lastSeenAt: Date
}

nonisolated struct LiveActivityPushToStartTokenRequest: Codable {
	let installationID: String
	let token: String
	let isDebug: Bool
}

nonisolated struct RemoveLiveActivityTokenRequest: Codable {
	let installationID: String
}

nonisolated struct LiveActivityUpdateTokenRequest: Codable {
	let installationID: String
	let token: String
	let isDebug: Bool
}

nonisolated struct ReconcileLiveActivityRequest: Codable {
	let installationID: String
}

nonisolated struct ReconcileLiveActivityResponse: Codable {
	let started: Bool
}

nonisolated struct TestNotificationResponse: Codable {
	let deliveredDeviceCount: Int
}

extension AccountProfile {
	init(_ response: UserProfileResponse) {
		id = response.id.uuidString
		email = response.email
		displayName = response.displayName
		createdAt = response.createdAt
	}
}
