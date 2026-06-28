//
//   AccountDTOs.swift
//   Shared
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

extension AccountProfile {
	init(_ response: UserProfileResponse) {
		id = response.id.uuidString
		email = response.email
		displayName = response.displayName
		createdAt = response.createdAt
	}
}
