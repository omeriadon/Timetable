//
//  WatchTimetableSyncStore.swift
//  Timetable
//
//  Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI
import WatchConnectivity
import WidgetKit

@MainActor
@Observable
final class WatchTimetableSyncStore: NSObject, WCSessionDelegate {
	private var isActivated = false

	var alertMessage: String?

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

	func session(_ session: WCSession,
	             activationDidCompleteWith activationState: WCSessionActivationState,
	             error: Error?)
	{
		if let error {
			alertMessage = "WatchConnectivity activation failed: \(error.localizedDescription)"
		}
	}

	func sessionReachabilityDidChange(_ session: WCSession) {}

	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		handleIncomingPayload(applicationContext, source: "applicationContext")
	}

	func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
		handleIncomingPayload(message, source: "message")
	}

	func session(_ session: WCSession,
	             didReceiveMessage message: [String: Any],
	             replyHandler: @escaping ([String: Any]) -> Void)
	{
		handleIncomingPayload(message, source: "message")
		replyHandler(["status": "ok"])
	}

	private func handleIncomingPayload(_ payload: [String: Any], source: String) {
		// ERROR
		if let payloadError = payload["error"] as? String {
			alertMessage = payloadError
			return
		}

		let previousTimetable = Defaults[.timetable]
		let previousReceived = Defaults[.receivedTimetables]

		// CLASSES
		if let timetableData = payload["timetableData"] as? Data {
			do {
				Defaults[.timetable] = try JSONDecoder().decode([Class].self, from: timetableData)
			} catch {
				print("[Watch] timetable decode failed: \(error)")
			}
		}

		// RECEIVED
		if let receivedData = payload["receivedTimetables"] as? Data {
			do {
				Defaults[.receivedTimetables] = try JSONDecoder().decode([ReceivedTimetable].self, from: receivedData)
			} catch {
				print("[Watch] receivedTimetables decode failed: \(error)")
			}
		}

		let changed =
			previousTimetable != Defaults[.timetable] ||
			previousReceived != Defaults[.receivedTimetables]

		if changed {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}
}
