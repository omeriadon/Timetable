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
		SessionStore.shared.configureWatchSessionDistribution(
			authenticated: { [weak self] accessToken, refreshToken, profile in
				self?.pushAuthenticatedSession(
					accessToken: accessToken,
					refreshToken: refreshToken,
					profile: profile
				)
			},
			signedOut: { [weak self] in
				self?.pushSignedOutSession()
			}
		)
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

	func pushTimetable() {
		Print("Skipped obsolete timetable transfer to watch", category: .watch)
	}

	func pushAuthenticatedSession(accessToken: String, refreshToken: String, profile: AccountProfile) {
		do {
			try send(.authenticated(
				accessToken: accessToken,
				refreshToken: refreshToken,
				profile: profile
			))
			Print("Sent authenticated session state to watch", category: .watch)
		} catch {
			PrintError("Failed to send authenticated session state to watch", category: .watch, error: error)
		}
	}

	func pushSignedOutSession() {
		do {
			try send(.signedOut())
			Print("Sent signed-out session state to watch", category: .watch)
		} catch {
			PrintError("Failed to send signed-out session state to watch", category: .watch, error: error)
		}
	}

	private func send(_ envelope: WatchSessionEnvelope) throws {
		activateIfNeeded()
		let payload = try ["sessionEnvelope": JSONEncoder().encode(envelope)]
		let session = WCSession.default
		try session.updateApplicationContext(payload)

		if session.isReachable {
			session.sendMessage(payload, replyHandler: nil) { error in
				PrintError("Watch live session sync failed", category: .watch, error: error)
			}
		}
	}

	func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
		if let error {
			PrintError("WatchConnectivity activation failed: \(error.localizedDescription)")
		}
	}

	func sessionDidBecomeInactive(_: WCSession) {}

	func sessionDidDeactivate(_ session: WCSession) {
		session.activate()
	}
}
