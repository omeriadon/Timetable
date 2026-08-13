//
//   NotificationRegistrationService.swift
//   Main
//

import Defaults
import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class NotificationRegistrationService {
	static let shared = NotificationRegistrationService(networkManager: .shared)

	enum RegistrationState: Equatable {
		case idle
		case registering
		case tokenReceived
		case registered
		case failed(String)
	}

	private(set) var registrationState: RegistrationState = .idle
	private(set) var hasLocalToken = !Defaults[.pendingAPNsToken].isEmpty

	private let networkManager: NetworkManager
	private var badgeID = UUID()
	private var uploadTask: Task<Void, Never>?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
		if Defaults[.hasRegisteredAPNsToken] {
			registrationState = .registered
		} else if hasLocalToken {
			registrationState = .tokenReceived
		}
	}

	func requestRemoteRegistration() async {
		Print("Requesting remote APNs registration", category: .network)
		do {
			_ = try await requestNotificationPermission()
		} catch {
			PrintError("Notification authorization request failed", category: .network, error: error)
		}

		badgeID = UUID()
		registrationState = .registering
		UIApplication.shared.registerForRemoteNotifications()
	}

	func requestNotificationPermission() async throws -> Bool {
		try await UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		)
	}

	func receive(deviceToken: Data) async {
		let token = deviceToken.map { String(format: "%02x", $0) }.joined()
		Print("Received APNs device token", category: .network)
		if Defaults[.pendingAPNsToken] != token {
			Defaults[.pendingAPNsToken] = token
			Defaults[.hasRegisteredAPNsToken] = false
		}
		hasLocalToken = true

		guard SessionStore.shared.isAuthenticated else {
			registrationState = .tokenReceived
			StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Device is ready", view: .success)
			return
		}

		await uploadPendingToken()
	}

	func uploadPendingToken() async {
		Print("Synchronizing pending APNs token", category: .network)
		if let uploadTask {
			await uploadTask.value
			return
		}
		let task = Task { @MainActor in
			await performUploadPendingToken()
		}
		uploadTask = task
		await task.value
		uploadTask = nil
	}

	private func performUploadPendingToken() async {
		guard SessionStore.shared.isAuthenticated else { return }
		let token = Defaults[.pendingAPNsToken]
		guard !token.isEmpty else {
			await requestRemoteRegistration()
			return
		}

		registrationState = .registering
		for attempt in 1 ... 3 {
			do {
				try await registerCurrentDevice(apnsToken: token)
				Defaults[.hasRegisteredAPNsToken] = true
				registrationState = .registered
				Print("Device registered for APNs", category: .network)
				return
			} catch {
				PrintError("APNs token upload attempt \(attempt) failed", category: .network, error: error)
				if attempt < 3 {
					try? await Task.sleep(for: .seconds(attempt))
					continue
				}

				Defaults[.hasRegisteredAPNsToken] = false
				registrationState = .failed(error.localizedDescription)
				StatusBadgeManager.shared.addBadge(
					id: badgeID,
					title: "Device registration failed",
					secondaryText: error.localizedDescription,
					priority: 5,
					view: .error
				)
			}
		}
	}

	private func registerCurrentDevice(apnsToken: String) async throws {
		let identity = ClientIdentityProvider.shared.identity()
		let _: UserDeviceResponse = try await networkManager.send(
			.v1CurrentDevice,
			body: RegisterUserDeviceRequest(
				installationID: identity.installationID,
				platform: identity.platform.rawValue,
				apnsToken: apnsToken,
				isDebug: Self.isDebug
			)
		)
	}

	func clearLocalRegistration() {
		Defaults[.hasRegisteredAPNsToken] = false
		registrationState = hasLocalToken ? .tokenReceived : .idle
	}

	func registrationFailed(_ error: (any Error)? = nil) {
		PrintError("APNs registration failed", category: .network, error: error)
		let message = error?.localizedDescription ?? "Apple Push Notification registration failed."
		registrationState = .failed(message)
		StatusBadgeManager.shared.addBadge(
			id: badgeID,
			title: "Device registration failed",
			secondaryText: message,
			priority: 5,
			view: .error
		)
	}

	private static var isDebug: Bool {
		#if DEBUG
			true
		#else
			false
		#endif
	}
}

private nonisolated struct EmptyRequest: Codable {}

private extension Endpoint {
	static let v1CurrentDevice = Endpoint("/v1/devices/current", method: .put)
}
