//
//  syncToWatchAsync.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

@MainActor
func syncToWatchAsync(
	classes: [Class],
	displayMode: DisplayMode,
	watchSync: PhoneWatchSyncBridge,
	statusUpdate: @escaping (SyncMode) -> Void
) async {
	let startedAt = Date()
	statusUpdate(.loading)
	print("[iOS] Starting WatchConnectivity sync...")

	do {
		try watchSync.pushTimetable(classes, displayMode: displayMode)
		print("[iOS] ✓ Sync request sent to watch")

		let elapsed = Date().timeIntervalSince(startedAt)
		if elapsed < 0.35 {
			let remaining = UInt64((0.35 - elapsed) * 1_000_000_000)
			try? await Task.sleep(nanoseconds: remaining)
		}

		statusUpdate(.success)
		print("[iOS] Sync completed, showing checkmark")

		try? await Task.sleep(nanoseconds: 1_000_000_000)
		statusUpdate(.normal)

	} catch {
		print("[iOS] ✗ Sync failed: \(error.localizedDescription)")
		statusUpdate(.error)
		try? await Task.sleep(nanoseconds: 1_000_000_000)
		statusUpdate(.normal)
	}
}
