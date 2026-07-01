//
//   NotificationRegistrationService.swift
//   Main
//
//   Created by Codex on 29/6/2026.
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

		private let networkManager: NetworkManager

		private init(networkManager: NetworkManager) {
			self.networkManager = networkManager
		}

		func reconcileWithStoredPreference() async {
			_ = await reconcile(enabled: Defaults[.accountSettings].notificationsEnabled)
		}

		func reconcile(enabled: Bool) async -> Bool {
			if enabled {
				do {
					let center = UNUserNotificationCenter.current()
					let current = await center.notificationSettings().authorizationStatus
					let granted: Bool = if current == .notDetermined {
						try await center.requestAuthorization(options: [.alert, .sound, .badge])
					} else {
						current == .authorized || current == .provisional || current == .ephemeral
					}
					guard granted else { return false }
					UIApplication.shared.registerForRemoteNotifications()
					return true
				} catch {
					PrintError("Notification authorization failed", category: .network, error: error)
					return false
				}
			}

			UIApplication.shared.unregisterForRemoteNotifications()
			do {
				try await networkManager.send(.v1CurrentDeviceDelete, body: RemoveUserDeviceRequest(installationID: Defaults[.installationID]))
			} catch NetworkError.offline {
				return true
			} catch {
				PrintError("Device notification removal failed", category: .network, error: error)
			}
			return true
		}

		func upload(deviceToken: Data) async {
			guard Defaults[.accountSettings].notificationsEnabled else { return }
			let token = deviceToken.map { String(format: "%02x", $0) }.joined()
			do {
				let _: UserDeviceResponse = try await networkManager.send(
					.v1CurrentDevice,
					body: RegisterUserDeviceRequest(
						installationID: Defaults[.installationID],
						platform: Self.platform,
						apnsToken: token
					)
				)
			} catch {
				PrintError("APNs token upload failed", category: .network, error: error)
			}
		}

		func sendTestNotification() async throws -> Int {
			let response: TestNotificationResponse = try await networkManager.send(.v1TestNotification, body: EmptyRequest())
			return response.deliveredDeviceCount
		}

		private static var platform: String {
			"iOS"
		}
	}

	private nonisolated struct EmptyRequest: Codable {}

	private extension Endpoint {
		static let v1CurrentDevice = Endpoint("/v1/devices/current", method: .put)
		static let v1TestNotification = Endpoint("/v1/notifications/test", method: .post)

		static let v1CurrentDeviceDelete = Endpoint("/v1/devices/current", method: .delete)
	}
#endif
