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
					appVersion: Bundle.main.appVersion,
					appBuild: Bundle.main.buildNumber,
					isDebug: Self.isDebug,
					isTestFlight: AppChannel.current == .testFlight,
					isOSBeta: Self.isOSBeta
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

	private static var isOSBeta: Bool {
		let versionString = ProcessInfo.processInfo.operatingSystemVersionString
		guard let buildStart = versionString.range(of: "(Build "),
		      let buildEnd = versionString[buildStart.upperBound...].firstIndex(of: ")")
		else {
			return false
		}

		let build = versionString[buildStart.upperBound ..< buildEnd]
		return build.last?.isLetter == true
	}
}

private extension Endpoint {
	static let v1CurrentDeviceSynchronize = Endpoint("/v1/devices/current/synchronize", method: .put)
	static let v1CurrentDeviceDelete = Endpoint("/v1/devices/current", method: .delete)
}
