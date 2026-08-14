import Defaults
import Foundation
import UserNotifications
import WatchKit

@MainActor
final class WatchNotificationRegistrationService {
	static let shared = WatchNotificationRegistrationService(networkManager: .shared)

	private let networkManager: NetworkManager

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func requestRemoteRegistration() async {
		do {
			_ = try await UNUserNotificationCenter.current().requestAuthorization(
				options: [.alert, .badge, .sound]
			)
		} catch {
			PrintError("Watch notification authorization request failed", category: .network, error: error)
		}

		WKExtension.shared().registerForRemoteNotifications()
	}

	func receive(deviceToken: Data) async {
		let token = deviceToken.map { String(format: "%02x", $0) }.joined()
		Defaults[.pendingAPNsToken] = token
		Defaults[.hasRegisteredAPNsToken] = false
		await uploadPendingToken()
	}

	func uploadPendingToken() async {
		guard SessionStore.shared.isAuthenticated else {
			return
		}

		let token = Defaults[.pendingAPNsToken]
		guard !token.isEmpty else {
			await requestRemoteRegistration()
			return
		}

		do {
			let identity = ClientIdentityProvider.shared.identity(for: .watchOS)
			let _: UserDeviceResponse = try await networkManager.send(
				.v1CurrentWatchDevice,
				body: RegisterUserDeviceRequest(
					installationID: identity.installationID,
					platform: identity.platform.rawValue,
					apnsToken: token,
					isDebug: Self.isDebug
				)
			)
			Defaults[.hasRegisteredAPNsToken] = true
		} catch {
			Defaults[.hasRegisteredAPNsToken] = false
			StatusBadgeManager.shared.present(error: error, title: "Watch Notification Registration Failed")
		}
	}

	func registrationFailed(_ error: any Error) {
		Defaults[.hasRegisteredAPNsToken] = false
		StatusBadgeManager.shared.present(error: error, title: "Watch Notification Registration Failed")
	}

	func clearLocalRegistration() {
		Defaults[.hasRegisteredAPNsToken] = false
	}

	private static var isDebug: Bool {
		#if DEBUG
			true
		#else
			false
		#endif
	}
}

private extension Endpoint {
	static let v1CurrentWatchDevice = Endpoint("/v1/devices/current", method: .put)
}
