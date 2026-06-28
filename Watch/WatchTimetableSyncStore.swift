//
//   WatchTimetableSyncStore.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import SwiftUI
import WatchConnectivity

@MainActor
@Observable
final class WatchTimetableSyncStore: NSObject, WCSessionDelegate {
	private var isActivated = false

	var alertMessage: String?

	override init() {
		super.init()
		SessionStore.shared.configureAccountBootstrap {
			try await WatchAccountBootstrapService.shared.bootstrap()
		}
	}

	func activateIfNeeded() {
		guard WCSession.isSupported() else {
			return
		}
		guard !isActivated else { return }

		let session = WCSession.default
		session.delegate = self
		session.activate()
		isActivated = true
	}

	func session(_: WCSession,
	             activationDidCompleteWith _: WCSessionActivationState,
	             error: Error?)
	{
		if let error {
			alertMessage = "WatchConnectivity activation failed: \(error.localizedDescription)"
		}
	}

	func sessionReachabilityDidChange(_: WCSession) {}

	func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		handleIncomingPayload(applicationContext, source: "applicationContext")
	}

	func session(_: WCSession, didReceiveMessage message: [String: Any]) {
		handleIncomingPayload(message, source: "message")
	}

	func session(_: WCSession,
	             didReceiveMessage message: [String: Any],
	             replyHandler: @escaping ([String: Any]) -> Void)
	{
		handleIncomingPayload(message, source: "message")
		replyHandler(["status": "ok"])
	}

	private func handleIncomingPayload(_ payload: [String: Any], source _: String) {
		if let payloadError = payload["error"] as? String {
			alertMessage = payloadError
			return
		}

		guard let envelopeData = payload["sessionEnvelope"] as? Data else { return }
		do {
			let envelope = try JSONDecoder().decode(WatchSessionEnvelope.self, from: envelopeData)
			Task { @MainActor [weak self] in
				do {
					try await SessionStore.shared.receiveWatchSession(envelope)
				} catch {
					self?.alertMessage = error.localizedDescription
				}
			}
		} catch {
			alertMessage = "The iPhone sent invalid account data."
			PrintError("[Watch] session envelope decode failed", category: .watch, error: error)
		}
	}
}
