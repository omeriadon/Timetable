//
//   NotificationRegistrationService.swift
//   Main
//

#if os(iOS)
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

		private init(networkManager: NetworkManager) {
			self.networkManager = networkManager
			if Defaults[.hasRegisteredAPNsToken] {
				registrationState = .registered
			} else if hasLocalToken {
				registrationState = .tokenReceived
			}
		}

		func requestRemoteRegistration() {
			badgeID = UUID()
			registrationState = .registering
			StatusBadgeManager.shared.addBadge(
				id: badgeID,
				title: "Registering this device…",
				priority: 5,
				view: .progressView
			)
			UIApplication.shared.registerForRemoteNotifications()
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
				requestRemoteRegistration()
				return
			}

			registrationState = .registering
			do {
				let _: UserDeviceResponse = try await networkManager.send(
					.v1CurrentDevice,
					body: RegisterUserDeviceRequest(
						installationID: Defaults[.installationID],
						platform: Self.platform,
						apnsToken: token,
						isDebug: Self.isDebug
					)
				)
				Defaults[.hasRegisteredAPNsToken] = true
				registrationState = .registered
				StatusBadgeManager.shared.addBadge(id: badgeID, title: "Device registered", priority: 5, view: .success)
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
			guard SessionStore.shared.isAuthenticated else { return }
			do {
				try await networkManager.send(
					.v1CurrentDeviceDelete,
					body: RemoveUserDeviceRequest(installationID: Defaults[.installationID])
				)
				Defaults[.hasRegisteredAPNsToken] = false
				registrationState = hasLocalToken ? .tokenReceived : .idle
			} catch {
				PrintError("Device notification removal failed", category: .network, error: error)
			}
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

		private static var platform: String {
			"iOS"
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
#endif
