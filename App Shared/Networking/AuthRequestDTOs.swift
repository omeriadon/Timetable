//
//   AuthRequestDTOs.swift
//   App Shared
//

import Foundation

nonisolated struct RegisterRequest: Codable {
	let email: String
	let password: String
	let displayName: String
	let platform: Platform.RawValue
	let installationID: String
}

nonisolated struct LoginRequest: Codable {
	let email: String
	let password: String
	let platform: Platform.RawValue
	let installationID: String
}

nonisolated struct RefreshRequest: Codable {
	let refreshToken: String
}

nonisolated struct VerificationCodeRequest: Codable {
	let email: String
	let installationID: String
}

nonisolated struct VerificationRegistrationRequest: Codable {
	let email: String
	let code: String
	let password: String
	let platform: Platform.RawValue
	let installationID: String
}

nonisolated struct LogoutRequest: Codable {
	let refreshToken: String
}

nonisolated struct WatchSessionRequest: Codable {
	let installationID: String
}
