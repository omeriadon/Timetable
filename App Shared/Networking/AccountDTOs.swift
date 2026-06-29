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
}

nonisolated struct OwnerTimetableResponse: Codable {
	let subjects: [Subject]
	let revision: Int
	let updatedAt: Date?
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
	let isDeleted: Bool
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
		isDeleted = timetable.isDeleted
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
			isDeleted: isDeleted
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
}

nonisolated struct UserDeviceResponse: Codable {
	let installationID: String
	let platform: String
	let lastSeenAt: Date
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
