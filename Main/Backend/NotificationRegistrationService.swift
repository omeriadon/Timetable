//
//   NotificationRegistrationService.swift
//   Main
//

#if os(iOS)
	import UIKit
#elseif os(macOS)
	import AppKit
#endif
import Defaults
import Foundation
import Observation
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

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
		if Defaults[.hasRegisteredAPNsToken] {
			registrationState = .registered
		} else if hasLocalToken {
			registrationState = .tokenReceived
		}
	}

	func requestRemoteRegistration() async {
		do {
			let granted = try await requestNotificationPermission()
			guard granted else {
				registrationFailed(NSError(
					domain: "Notifications",
					code: 1,
					userInfo: [NSLocalizedDescriptionKey: "Notification permission was denied."]
				))
				return
			}

			badgeID = UUID()
			registrationState = .registering

			#if os(iOS)
				UIApplication.shared.registerForRemoteNotifications()

			#elseif os(macOS)
				NSApplication.shared.registerForRemoteNotifications(matching: [.alert, .badge, .sound])

			#else
				registrationFailed()
			#endif

		} catch {
			registrationFailed(error)
		}
	}

	func requestNotificationPermission() async throws -> Bool {
		try await UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]
		)
	}

	func receive(deviceToken: Data) async {
		let token = deviceToken.map { String(format: "%02x", $0) }.joined()
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
		guard SessionStore.shared.isAuthenticated else { return }
		let token = Defaults[.pendingAPNsToken]
		guard !token.isEmpty else {
			await requestRemoteRegistration()
			return
		}

		registrationState = .registering
		do {
			let _: UserDeviceResponse = try await networkManager.send(
				.v1CurrentDevice,
				body: RegisterUserDeviceRequest(
					installationID: ClientIdentityProvider.shared.identity().installationID,
					platform: ClientIdentityProvider.shared.identity().platform.rawValue,
					apnsToken: token,
					isDebug: Self.isDebug
				)
			)
			Defaults[.hasRegisteredAPNsToken] = true
			registrationState = .registered

			Print("Device registered")
		} catch {
			Defaults[.hasRegisteredAPNsToken] = false
			registrationState = .failed(error.localizedDescription)
			StatusBadgeManager.shared.addBadge(
				id: badgeID,
				title: "Device registration failed",
				secondaryText: error.localizedDescription,
				priority: 5,
				view: .error
			)
			PrintError("APNs token upload failed", category: .network, error: error)
		}
	}

	func removeServerRegistration() async {
		if SessionStore.shared.isAuthenticated {
			do {
				let identity = ClientIdentityProvider.shared.identity()
				try await networkManager.send(
					.v1CurrentDeviceDelete,
					body: RemoveUserDeviceRequest(
						installationID: identity.installationID,
						platform: identity.platform.rawValue
					)
				)
			} catch {
				PrintError("Device notification removal failed", category: .network, error: error)
			}
		}
		Defaults[.hasRegisteredAPNsToken] = false
		registrationState = hasLocalToken ? .tokenReceived : .idle
	}

	func registrationFailed(_ error: (any Error)? = nil) {
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

	func sendTestNotification() async throws -> Int {
		let response: TestNotificationResponse = try await networkManager.send(.v1TestNotification, body: EmptyRequest())
		return response.deliveredDeviceCount
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
	static let v1TestNotification = Endpoint("/v1/notifications/test", method: .post)
	static let v1CurrentDeviceDelete = Endpoint("/v1/devices/current", method: .delete)
}
