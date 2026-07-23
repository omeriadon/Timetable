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
		let identity = ClientIdentityProvider.shared.identity()
		for attempt in 1 ... 3 {
			do {
				let _: UserDeviceResponse = try await networkManager.send(
					.v1CurrentDevice,
					body: RegisterUserDeviceRequest(
						installationID: identity.installationID,
						platform: identity.platform.rawValue,
						apnsToken: token,
						isDebug: Self.isDebug
					)
				)
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

	func removeServerRegistration() async {
		Print("Removing server APNs registration", category: .network)
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
	static let v1CurrentDeviceDelete = Endpoint("/v1/devices/current", method: .delete)
}
