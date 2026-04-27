//
//  PhoneWatchSyncBridge.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 27/4/2026.
//

import Foundation
import WatchConnectivity
import Combine


final class PhoneWatchSyncBridge: NSObject, ObservableObject, WCSessionDelegate {
	@Published var lastError: String?

	private var latestClasses: [Class] = []
	private var isActivated = false

	func activateIfNeeded() {
		guard WCSession.isSupported() else {
			print("[iOS] WCSession not supported on this device")
			return
		}
		guard !isActivated else { return }

		let session = WCSession.default
		session.delegate = self
		session.activate()
		isActivated = true
		print("[iOS] WCSession activate() called")
	}

	func updateLatestClasses(_ classes: [Class]) {
		latestClasses = classes
		print("[iOS] Updated latest classes snapshot: \(classes.count) classes")
	}

	func pushTimetable(_ classes: [Class], displayMode: DisplayMode) throws {
		activateIfNeeded()
		latestClasses = classes

		print("[iOS] Encoding \(classes.count) classes for watch...")
		let data = try JSONEncoder().encode(classes)
		print("[iOS] Encoded successfully: \(data.count) bytes")

		let displayModeData = try JSONEncoder().encode(displayMode)

		let payload: [String: Any] = [
			"timetableData": data,
			"displayMode": displayModeData,
			"updatedAt": Date().timeIntervalSince1970,
		]

		let session = WCSession.default
		try session.updateApplicationContext(payload)
		if session.isReachable {
			session.sendMessage(payload, replyHandler: nil) { error in
				DispatchQueue.main.async {
					self.lastError = "Watch live sync failed: \(error.localizedDescription)"
				}
			}
		}
		print("[iOS] updateApplicationContext sent with displayMode: \(displayMode.rawValue)")
	}

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("[iOS] WC activation completed with state: \(activationState.rawValue)")
		if let error {
			print("[iOS] WC activation error: \(error.localizedDescription)")
			DispatchQueue.main.async {
				self.lastError = "WatchConnectivity activation failed: \(error.localizedDescription)"
			}
		}
	}

	func sessionDidBecomeInactive(_ session: WCSession) {
		print("[iOS] WC session became inactive")
	}

	func sessionDidDeactivate(_ session: WCSession) {
		print("[iOS] WC session deactivated; reactivating")
		session.activate()
	}
}
