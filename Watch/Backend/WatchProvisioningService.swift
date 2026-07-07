import Defaults
import Foundation
import WatchConnectivity

private enum WatchProvisioningError: LocalizedError {
	case invalidResponse
	case phoneUnavailable
	case provisioningFailed(String)

	var errorDescription: String? {
		switch self {
			case .invalidResponse:
				"The iPhone returned an invalid Watch session."
			case .phoneUnavailable:
				"The paired iPhone is not reachable."
			case let .provisioningFailed(message):
				message
		}
	}
}

@Observable
@MainActor
final class WatchProvisioningService: NSObject, WCSessionDelegate {
	static let shared = WatchProvisioningService()

	var isRequesting = false

	private var didConfigureSession = false
	private var timeoutTask: Task<Void, Never>?

	func activate() {
		guard WCSession.isSupported() else { return }

		let session = WCSession.default

		if !didConfigureSession {
			session.delegate = self
			didConfigureSession = true
		}

		if session.activationState == .notActivated {
			session.activate()
		}
	}

	func requestSessionIfPossible() {
		guard WCSession.isSupported(), !isRequesting else { return }

		activate()

		let session = WCSession.default

		guard session.activationState == .activated, session.isReachable else {
			StatusBadgeManager.shared.present(
				error: WatchProvisioningError.phoneUnavailable,
				title: "Unable to Sign In"
			)
			return
		}

		isRequesting = true
		startTimeout()

		let installationID = Defaults[.installationID]

		session.sendMessage(
			["watchSessionInstallationID": installationID],
			replyHandler: { reply in
				Task { @MainActor in
					self.finishRequest()

					do {
						if let message = reply["error"] as? String {
							throw WatchProvisioningError.provisioningFailed(message)
						}

						guard let data = reply["watchSession"] as? Data else {
							throw WatchProvisioningError.invalidResponse
						}

						let response = try JSONDecoder().decode(TokenResponse.self, from: data)
						try await SessionStore.shared.acceptProvisionedSession(response)
					} catch {
						StatusBadgeManager.shared.present(
							error: error,
							title: "Unable to Sign In"
						)
					}
				}
			},
			errorHandler: { error in
				Task { @MainActor in
					self.finishRequest()

					StatusBadgeManager.shared.present(
						error: error,
						title: "Unable to Sign In"
					)
				}
			}
		)
	}

	private func startTimeout() {
		timeoutTask?.cancel()

		timeoutTask = Task { [weak self] in
			try? await Task.sleep(for: .seconds(10))

			await MainActor.run {
				guard let self, self.isRequesting else { return }

				self.finishRequest()

				StatusBadgeManager.shared.present(
					error: WatchProvisioningError.phoneUnavailable,
					title: "Unable to Sign In"
				)
			}
		}
	}

	private func finishRequest() {
		timeoutTask?.cancel()
		timeoutTask = nil
		isRequesting = false
	}

	nonisolated func session(
		_: WCSession,
		activationDidCompleteWith _: WCSessionActivationState,
		error _: Error?
	) {
		// Nothing required here if requestSessionIfPossible only sends when already activated.
	}
}
