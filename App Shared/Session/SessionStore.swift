//
//   SessionStore.swift
//   App Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import AuthenticationServices
import Defaults
import Foundation
import Observation

enum SessionStoreError: LocalizedError {
	case credentialPersistenceFailed
	case invalidIdentityToken
	case missingRefreshToken

	var errorDescription: String? {
		switch self {
			case .credentialPersistenceFailed:
				"Session credentials could not be stored."
			case .invalidIdentityToken:
				"The Apple identity token was invalid."
			case .missingRefreshToken:
				"Refresh token is missing."
		}
	}
}

@MainActor
@Observable
final class SessionStore {
	static let shared = SessionStore(networkManager: .shared)

	private(set) var state: AuthenticationState = .signedOut

	var isAuthenticated: Bool {
		if case .authenticated = state { return true }
		return false
	}

	private let networkManager: NetworkManager
	private let accessTokenKey = "com.omeriadon.Timetable.session.accessToken"
	private let refreshTokenKey = "com.omeriadon.Timetable.session.refreshToken"
	private var accountBootstrapHandler: (() async throws -> Void)?
	private var authenticatedHandler: (() async -> Void)?
	private var signingOutHandler: (() async -> Void)?
	private var watchAuthenticatedHandler: ((String, String, AccountProfile) -> Void)?
	private var watchSignedOutHandler: (() -> Void)?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
		configureNetworkAuthentication()
	}

	func restore() async {
		Print("Restoring session state", category: .account)
		state = .restoring
		configureNetworkAuthentication()

		guard let profile = Defaults[.accountProfile] else {
			clearSessionState()
			return
		}

		if let accessToken, !accessToken.isEmpty {
			state = .authenticated(profile)
			syncSessionToWatch(profile: profile)
			await authenticatedHandler?()
			if let accountBootstrapHandler {
				try? await accountBootstrapHandler()
			}
			Print("Restored authenticated session for \(profile.id)", category: .account)
			return
		}

		guard refreshToken != nil else {
			clearSessionState()
			return
		}

		do {
			try await refreshSilently()
		} catch let NetworkError.server(statusCode, response)
			where statusCode == 401 || response.code == .sessionExpired
		{
			clearSessionState()
		} catch let error as NetworkError {
			state = .authenticated(profile)
			PrintError(
				"Using cached authenticated session after refresh failure for \(profile.id)",
				category: .account,
				error: error
			)
		} catch {
			PrintError("Silent restore failed", category: .account, error: error)
			clearSessionState()
		}
	}

	func signUp(email: String, password: String, displayName: String) async throws {
		Print("Signing up account", category: .account)
		let response: TokenResponse = try await networkManager.send(
			.v1AuthRegister,
			body: RegisterRequest(
				email: email,
				password: password,
				displayName: displayName
			)
		)
		try await apply(response, bootstrap: true)
	}

	func signIn(email: String, password: String) async throws {
		Print("Signing in account", category: .account)
		let response: TokenResponse = try await networkManager.send(
			.v1AuthLogin,
			body: LoginRequest(email: email, password: password)
		)
		try await apply(response, bootstrap: true)
	}

	func signInWithApple(_ authorization: ASAuthorization) async throws {
		guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
			throw SessionStoreError.invalidIdentityToken
		}

		guard let identityTokenData = credential.identityToken,
		      let identityToken = String(data: identityTokenData, encoding: .utf8)
		else {
			throw SessionStoreError.invalidIdentityToken
		}

		let formatter = PersonNameComponentsFormatter()
		formatter.style = .default
		let displayName = credential.fullName
			.map { formatter.string(from: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
			.flatMap { $0.isEmpty ? nil : $0 }

		let response: TokenResponse = try await networkManager.send(
			.v1AuthApple,
			body: AppleSignInRequest(
				identityToken: identityToken,
				displayName: displayName
			)
		)
		try await apply(response, bootstrap: true)
	}

	func refreshSilently() async throws {
		guard let refreshToken else {
			throw SessionStoreError.missingRefreshToken
		}

		Print("Refreshing session silently", category: .account)
		do {
			let response: TokenResponse = try await networkManager.send(
				.v1AuthRefresh,
				body: RefreshRequest(refreshToken: refreshToken)
			)
			try await apply(response, bootstrap: false)
		} catch let NetworkError.server(statusCode, response)
			where statusCode == 401 || response.code == .sessionExpired
		{
			clearSessionState()
			throw NetworkError.server(statusCode: statusCode, response: response)
		}
	}

	@discardableResult
	func refreshProfile() async throws -> AccountProfile {
		Print("Refreshing account profile", category: .account)
		let response: UserProfileResponse = try await networkManager.send(.v1Profile)
		return persist(response)
	}

	@discardableResult
	func updateProfile(displayName: String? = nil, email: String? = nil) async throws -> AccountProfile {
		Print("Updating account profile", category: .account)
		let response: UserProfileResponse = try await networkManager.send(
			.v1ProfileUpdate,
			body: UpdateProfileRequest(displayName: displayName, email: email)
		)
		return persist(response)
	}

	func signOut() async {
		Print("Signing out account", category: .account)
		await signingOutHandler?()
		if let refreshToken, accessToken != nil {
			do {
				try await networkManager.send(.v1AuthLogout, body: LogoutRequest(refreshToken: refreshToken))
			} catch {
				PrintError("Remote logout failed", category: .account, error: error)
			}
		}

		clearSessionState()
	}

	func deleteAccount() async throws {
		Print("Deleting account", category: .account)
		try await networkManager.send(.v1ProfileDelete)
		clearSessionState()
	}

	func configureWatchSessionDistribution(
		authenticated: @escaping (String, String, AccountProfile) -> Void,
		signedOut: @escaping () -> Void
	) {
		watchAuthenticatedHandler = authenticated
		watchSignedOutHandler = signedOut
	}

	func configureAccountBootstrap(_ bootstrap: @escaping () async throws -> Void) {
		accountBootstrapHandler = bootstrap
	}

	func configureDeviceLifecycle(
		authenticated: @escaping () async -> Void,
		signingOut: @escaping () async -> Void
	) {
		authenticatedHandler = authenticated
		signingOutHandler = signingOut
	}

	func receiveWatchSession(_ envelope: WatchSessionEnvelope) async throws {
		switch envelope.event {
			case .signedOut:
				clearSessionState()
			case .authenticated:
				guard let accessToken = envelope.accessToken,
				      let refreshToken = envelope.refreshToken,
				      let profile = envelope.profile,
				      !accessToken.isEmpty,
				      !refreshToken.isEmpty
				else {
					throw SessionStoreError.credentialPersistenceFailed
				}

				guard KeychainManager.save(string: accessToken, forKey: accessTokenKey),
				      KeychainManager.save(string: refreshToken, forKey: refreshTokenKey)
				else {
					throw SessionStoreError.credentialPersistenceFailed
				}

				Defaults[.accountProfile] = profile
				Defaults[.userDisplayName] = profile.displayName
				state = .authenticated(profile)
				configureNetworkAuthentication()
				await authenticatedHandler?()
				if let accountBootstrapHandler {
					try await accountBootstrapHandler()
				}
		}
	}

	private var accessToken: String? {
		KeychainManager.read(forKey: accessTokenKey)
	}

	private var refreshToken: String? {
		KeychainManager.read(forKey: refreshTokenKey)
	}

	private func configureNetworkAuthentication() {
		networkManager.configureAuthentication(
			accessToken: { [weak self] in
				self?.accessToken
			},
			refresh: { [weak self] in
				guard let self else { return }
				try await refreshSilently()
			}
		)
	}

	private func apply(_ response: TokenResponse, bootstrap: Bool) async throws {
		guard KeychainManager.save(string: response.accessToken, forKey: accessTokenKey),
		      KeychainManager.save(string: response.refreshToken, forKey: refreshTokenKey)
		else {
			KeychainManager.delete(forKey: accessTokenKey)
			KeychainManager.delete(forKey: refreshTokenKey)
			throw SessionStoreError.credentialPersistenceFailed
		}
		let profile = persist(response.user)
		state = .authenticated(profile)
		syncSessionToWatch(profile: profile)
		await authenticatedHandler?()
		if bootstrap, let accountBootstrapHandler {
			try await accountBootstrapHandler()
		}
		Print("Authenticated session for \(profile.id)", category: .account)
	}

	@discardableResult
	private func persist(_ response: UserProfileResponse) -> AccountProfile {
		let profile = AccountProfile(response)
		Defaults[.accountProfile] = profile
		Defaults[.userDisplayName] = profile.displayName
		Defaults[.lastServerSync] = Date.now
		if case .authenticated = state {
			state = .authenticated(profile)
		}
		return profile
	}

	private func clearSessionState() {
		KeychainManager.delete(forKey: accessTokenKey)
		KeychainManager.delete(forKey: refreshTokenKey)
		Defaults[.accountProfile] = nil
		Defaults[.hasCompletedAccountBootstrap] = false
		state = .signedOut
		networkManager.clearAuthentication()
		configureNetworkAuthentication()
		watchSignedOutHandler?()
		Print("Cleared local session state", category: .account)
	}

	private func syncSessionToWatch(profile: AccountProfile) {
		guard let accessToken, let refreshToken else { return }
		watchAuthenticatedHandler?(accessToken, refreshToken, profile)
	}
}

private extension Endpoint {
	static let v1AuthApple = Endpoint("/v1/auth/apple", method: .post, requiresAuthentication: false)
	static let v1AuthLogin = Endpoint("/v1/auth/login", method: .post, requiresAuthentication: false)
	static let v1AuthLogout = Endpoint("/v1/auth/logout", method: .delete)
	static let v1AuthRefresh = Endpoint("/v1/auth/refresh", method: .post, requiresAuthentication: false)
	static let v1AuthRegister = Endpoint("/v1/auth/register", method: .post, requiresAuthentication: false)
	static let v1Profile = Endpoint("/v1/profile")
	static let v1ProfileDelete = Endpoint("/v1/profile", method: .delete)
	static let v1ProfileUpdate = Endpoint("/v1/profile", method: .put)
}
