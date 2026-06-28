//
//   WatchSessionEnvelope.swift
//   App Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Foundation

nonisolated struct WatchSessionEnvelope: Codable {
	enum Event: String, Codable {
		case authenticated
		case signedOut
	}

	let event: Event
	let accessToken: String?
	let refreshToken: String?
	let profile: AccountProfile?
	let updatedAt: Date

	static func authenticated(
		accessToken: String,
		refreshToken: String,
		profile: AccountProfile
	) -> Self {
		Self(
			event: .authenticated,
			accessToken: accessToken,
			refreshToken: refreshToken,
			profile: profile,
			updatedAt: Date.now
		)
	}

	static func signedOut() -> Self {
		Self(
			event: .signedOut,
			accessToken: nil,
			refreshToken: nil,
			profile: nil,
			updatedAt: Date.now
		)
	}
}
