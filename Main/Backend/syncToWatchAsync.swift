//
//   syncToWatchAsync.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

@MainActor
func syncToWatchAsync(
	subjects _: [Subject],
	watchSync: PhoneWatchSyncBridge,
	statusUpdate: @escaping (SyncMode) -> Void
) async {
	let startedAt = Date()
	let badgeID = UUID()
	StatusBadgeManager.shared.addBadge(id: badgeID, title: "Syncing to Apple Watch", priority: 3, view: .progressView)
	statusUpdate(.loading)
	Print("[iOS] Starting WatchConnectivity sync...")

	watchSync.pushTimetable()
	Print("[iOS] ✓ Sync request sent to watch")

	let elapsed = Date().timeIntervalSince(startedAt)
	if elapsed < 0.35 {
		let remaining = UInt64((0.35 - elapsed) * 1_000_000_000)
		try? await Task.sleep(nanoseconds: remaining)
	}

	statusUpdate(.success)
	StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Synced to Apple Watch", view: .success)
	Print("[iOS] Sync completed, showing checkmark")

	try? await Task.sleep(nanoseconds: 1_000_000_000)
	statusUpdate(.normal)
}
