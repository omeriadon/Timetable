//
//   WatchTimetableSyncStore.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
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
		// ERROR
		if let payloadError = payload["error"] as? String {
			alertMessage = payloadError
			return
		}

		let previousTimetable = Defaults[.timetable]
		let previousReceived = Defaults[.receivedTimetables]

		// SUBJECTS
		if let timetableData = payload["timetableData"] as? Data {
			do {
				Defaults[.timetable] = try JSONDecoder().decode([Subject].self, from: timetableData)
			} catch {
				PrintError("[Watch] timetable decode failed: \(error)")
			}
		}

		// RECEIVED
		if let receivedData = payload["receivedTimetables"] as? Data {
			do {
				Defaults[.receivedTimetables] = try JSONDecoder().decode([ReceivedTimetable].self, from: receivedData)
			} catch {
				PrintError("[Watch] receivedTimetables decode failed: \(error)")
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
