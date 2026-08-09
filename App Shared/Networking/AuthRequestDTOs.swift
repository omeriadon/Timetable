//
//   AuthRequestDTOs.swift
//   App Shared
//

import Foundation

nonisolated struct LoginRequest: Codable, Sendable {
	let email: String
	let password: String
	let platform: Platform.RawValue
	let installationID: String
}

nonisolated struct RefreshRequest: Codable, Sendable {
	let refreshToken: String
}

nonisolated struct VerificationCodeRequest: Codable, Sendable {
	let email: String
	let installationID: String
}

nonisolated struct VerificationRegistrationRequest: Codable, Sendable {
	let email: String
	let code: String
	let password: String
	let platform: Platform.RawValue
	let installationID: String
}

nonisolated struct VerificationCodeResponse: Codable, Sendable {
	let expiresAt: Date
	let resendAvailableAt: Date
}

nonisolated struct LogoutRequest: Codable, Sendable {
	let refreshToken: String
}

nonisolated struct WatchSessionRequest: Codable, Sendable {
	let installationID: String
	let osMajorVersion: Int
}
