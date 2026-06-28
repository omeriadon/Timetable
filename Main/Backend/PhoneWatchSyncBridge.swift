//
//   PhoneWatchSyncBridge.swift
//   Main
//
//   Created by Adon Omeri on 27/4/2026.
//

import Defaults
import Foundation
import WatchConnectivity

final class PhoneWatchSyncBridge: NSObject, WCSessionDelegate {
	private var isActivated = false

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
		activateIfNeeded()

		let encoder = JSONEncoder()

		do {
			let timetableData = try encoder.encode(Defaults[.timetable])
			let receivedData = try encoder.encode(Defaults[.receivedTimetables])

			let payload: [String: Any] = [
				"timetableData": timetableData,
				"receivedTimetables": receivedData,
				"updatedAt": Date().timeIntervalSince1970,
			]

			let session = WCSession.default

			try session.updateApplicationContext(payload)

			if session.isReachable {
				session.sendMessage(payload, replyHandler: nil) { error in
					PrintError("Watch live sync failed: \(error.localizedDescription)")
				}
			}
		} catch {
			PrintError("Error encoding or updating application context: \(error.localizedDescription)")
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
