import Foundation

@MainActor
final class DeviceSynchronizationService {
	static let shared = DeviceSynchronizationService()

	private init() {}

	func synchronize() async {
		guard SessionStore.shared.isAuthenticated else { return }

		let identity = ClientIdentityProvider.shared.identity()
		let version = ProcessInfo.processInfo.operatingSystemVersion

		do {
			let _: UserDeviceResponse = try await NetworkManager.shared.send(
				.v1CurrentDeviceSynchronize,
				body: SynchronizeUserDeviceRequest(
					installationID: identity.installationID,
					platform: identity.platform.rawValue,
					osMajorVersion: version.majorVersion,
					osMinorVersion: version.minorVersion,
					isDebug: Self.isDebug,
					isBeta: Self.isBeta
				)
			)
			Print("Device synchronized", category: .network)
		} catch {
			PrintError("Device synchronization failed", category: .network, error: error)
		}
	}

	func remove() async {
		guard SessionStore.shared.isAuthenticated else { return }

		let identity = ClientIdentityProvider.shared.identity()
		do {
			try await NetworkManager.shared.send(
				.v1CurrentDeviceDelete,
				body: RemoveUserDeviceRequest(
					installationID: identity.installationID,
					platform: identity.platform.rawValue
				)
			)
			Print("Device removed", category: .network)
		} catch {
			PrintError("Device removal failed", category: .network, error: error)
		}
	}

	private static var isDebug: Bool {
		#if DEBUG
			true
		#else
			false
		#endif
	}

	private static var isBeta: Bool {
		guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
			return false
		}

		return build.last?.isLetter == true
	}
}

private extension Endpoint {
	static let v1CurrentDeviceSynchronize = Endpoint("/v1/devices/current/synchronize", method: .put)
	static let v1CurrentDeviceDelete = Endpoint("/v1/devices/current", method: .delete)
}
