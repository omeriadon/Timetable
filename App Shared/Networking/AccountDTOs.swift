//
//   AccountDTOs.swift
//   App Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Foundation

nonisolated struct TokenResponse: Codable {
	let accessToken: String
	let refreshToken: String
	let user: UserProfileResponse
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
	let id: UUID?
	let subjects: [Subject]
	let revision: Int
	let updatedAt: Date?
	let isSearchable: Bool

	private enum CodingKeys: String, CodingKey { case id, subjects, revision, updatedAt, isSearchable }

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decodeIfPresent(UUID.self, forKey: .id)
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
	let savedByCount: Int
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

nonisolated enum ReceivedTimetableAvailability: String, Codable {
	case available
	case deleted
}

nonisolated struct AuthoritativeReceivedTimetableDTO: Codable {
	let importID: UUID
	let id: UUID
	let title: String?
	let authorAccountID: UUID?
	let authorDisplayName: String?
	let sourceKind: SourceKind
	let subjects: [Subject]
	let revision: Int?
	let updatedAt: Date?
	let importedAt: Date
	let availability: ReceivedTimetableAvailability

	var receivedTimetable: ReceivedTimetable {
		ReceivedTimetable(
			id: id.uuidString,
			importID: importID.uuidString,
			issuerAccountID: authorAccountID?.uuidString ?? "",
			sourceKind: sourceKind,
			signedDisplayName: title ?? "Unavailable Timetable",
			authorDisplayName: authorDisplayName,
			subjects: subjects,
			receivedAt: importedAt,
			passUpdatedAt: updatedAt ?? importedAt,
			contentRevision: revision ?? 0,
			isDeleted: availability == .deleted,
			isShareable: availability == .available
		)
	}
}

nonisolated struct ReceivedTimetableImportRequest: Codable {
	let timetableID: UUID?
	let timetableLocator: String?
	init(timetableID: UUID) {
		self.timetableID = timetableID; timetableLocator = nil
	}

	init(timetableLocator: String) {
		timetableID = nil; self.timetableLocator = timetableLocator
	}
}

nonisolated enum TimetableShareAliasAvailabilityReason: String, Codable, Sendable {
	case empty, tooShort, tooLong, invalidCharacter, leadingSeparator, trailingSeparator, consecutiveSeparators, reserved, uuidShaped, taken
}

nonisolated struct TimetableShareAliasResponse: Codable, Sendable {
	let alias: String?
	let timetableID: UUID?
	let url: String?
}

nonisolated struct TimetableShareAliasAvailabilityResponse: Codable, Sendable {
	let normalizedAlias: String
	let isValid: Bool
	let isAvailable: Bool
	let isOwnedByCurrentUser: Bool
	let reason: TimetableShareAliasAvailabilityReason?
}

nonisolated struct TimetableShareAliasUpdateRequest: Codable, Sendable { let alias: String }

nonisolated struct RegisterUserDeviceRequest: Codable {
	let installationID: String
	let platform: String
	let apnsToken: String
	/// `true` when the token is from a debug/sandbox build.
	let isDebug: Bool
}

nonisolated struct RemoveUserDeviceRequest: Codable {
	let installationID: String
	let platform: String
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
