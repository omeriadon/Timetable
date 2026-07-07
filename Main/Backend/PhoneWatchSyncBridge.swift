//
//   PhoneWatchSyncBridge.swift
//   Main
//
//   Created by Adon Omeri on 27/4/2026.
//

import Foundation
import WatchConnectivity

final class PhoneWatchSyncBridge: NSObject, WCSessionDelegate {
	static let shared = PhoneWatchSyncBridge()

	private var isActivated = false

	override private init() {
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

	func sendAuthenticatedStateIfPossible() {
		send(action: WatchSessionMessage.authenticatedAction)
	}

	func sendSignedOutStateIfPossible() {
		send(action: WatchSessionMessage.signedOutAction)
	}

	func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
		guard let installationID = message[WatchSessionMessage.installationIDKey] as? String else {
			replyHandler([WatchSessionMessage.errorKey: "The Watch sign-in request was invalid."])
			return
		}
		Task { @MainActor in
			do {
				guard SessionStore.shared.isAuthenticated else {
					replyHandler([WatchSessionMessage.errorKey: "Sign in on iPhone first."])
					return
				}
				let response: TokenResponse = try await NetworkManager.shared.send(
					Endpoint("/v1/auth/watch-session", method: .post),
					body: WatchSessionRequest(installationID: installationID),
					context: .background
				)
				try replyHandler([WatchSessionMessage.sessionKey: JSONEncoder().encode(response)])
			} catch {
				replyHandler([WatchSessionMessage.errorKey: "The iPhone could not sign in this Watch."])
			}
		}
	}

	func sessionDidDeactivate(_ session: WCSession) {
		session.activate()
	}

	private func send(action: String) {
		activateIfNeeded()

		let session = WCSession.default
		guard session.activationState == .activated, session.isWatchAppInstalled, session.isReachable else { return }

		session.sendMessage(
			[WatchSessionMessage.actionKey: action],
			replyHandler: nil,
			errorHandler: { error in
				PrintError("Watch auth-state message failed", category: .account, error: error)
			}
		)
	}
}
