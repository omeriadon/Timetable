//
//   PhoneWatchSyncBridge.swift
//   Main
//
//   Created by Adon Omeri on 27/4/2026.
//

import Foundation
import WatchConnectivity

final class PhoneWatchSyncBridge: NSObject, WCSessionDelegate {
	private var isActivated = false

	override init() {
		super.init()
	}

	func activateIfNeeded() {
		guard WCSession.isSupported() else {
			Print("[iOS] WCSession not supported on this device")
			return
		}
		guard !isActivated else { return }

		let session = WCSession.default
		session.delegate = self
		session.activate()
		isActivated = true
		Print("[iOS] WCSession activate() called")
	}

	func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
		if let error {
			PrintError("WatchConnectivity activation failed: \(error.localizedDescription)")
		}
	}

	func sessionDidBecomeInactive(_: WCSession) {}

	func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
		guard let installationID = message["watchSessionInstallationID"] as? String else {
			replyHandler(["error": "The Watch sign-in request was invalid."])
			return
		}
		Task { @MainActor in
			do {
				guard SessionStore.shared.isAuthenticated else {
					replyHandler(["error": "Sign in on iPhone first."])
					return
				}
				let response: TokenResponse = try await NetworkManager.shared.send(
					Endpoint("/v1/auth/watch-session", method: .post),
					body: WatchSessionRequest(installationID: installationID),
					context: .background
				)
				try replyHandler(["watchSession": JSONEncoder().encode(response)])
			} catch {
				replyHandler(["error": "The iPhone could not sign in this Watch."])
			}
		}
	}

	func sessionDidDeactivate(_ session: WCSession) {
		session.activate()
	}
}
