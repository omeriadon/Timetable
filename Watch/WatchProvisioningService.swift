import Defaults
import Foundation
import WatchConnectivity

@MainActor
@Observable
final class WatchProvisioningService: NSObject, WCSessionDelegate {
	static let shared = WatchProvisioningService()
	private(set) var isRequesting = false

	func activate() {
		guard WCSession.isSupported() else { return }
		let session = WCSession.default
		session.delegate = self
		session.activate()
	}

	/// Whether the paired iPhone is currently reachable for a session push.
	var isPhoneReachable: Bool {
		guard WCSession.isSupported() else { return false }
		let session = WCSession.default
		return session.activationState == .activated && session.isReachable
	}

	/// Asks the paired iPhone to provision a session for this Watch.
	/// Silently does nothing if the phone is unreachable — this is optional sugar, not required.
	func requestSessionIfPossible() {
		guard WCSession.isSupported(), !isRequesting else { return }
		let session = WCSession.default
		session.delegate = self
		if session.activationState == .notActivated {
			session.activate()
		}
		// Silently bail if unreachable — no badge, no error. The Watch is independent.
		guard session.activationState == .activated, session.isReachable else { return }
		isRequesting = true
		let installationID = Defaults[.installationID]
		session.sendMessage(["watchSessionInstallationID": installationID], replyHandler: { reply in
			Task { @MainActor in
				self.isRequesting = false
				guard let data = reply["watchSession"] as? Data,
				      let response = try? JSONDecoder().decode(TokenResponse.self, from: data)
				else {
					// Silent failure — user can try the Watch's own sign-in instead.
					return
				}
				try? await SessionStore.shared.acceptProvisionedSession(response)
			}
		}, errorHandler: { _ in
			Task { @MainActor in
				self.isRequesting = false
				// Silent failure — phone connectivity is optional.
			}
		})
	}

	nonisolated func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {
		// Session activated — passively listen for iPhone-pushed sessions only.
		// Do NOT auto-request: the Watch is fully independent of the iPhone.
	}

	nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		Task { @MainActor in
			guard let data = applicationContext["watchSession"] as? Data,
			      let response = try? JSONDecoder().decode(TokenResponse.self, from: data)
			else { return }
			try? await SessionStore.shared.acceptProvisionedSession(response)
		}
	}
}
