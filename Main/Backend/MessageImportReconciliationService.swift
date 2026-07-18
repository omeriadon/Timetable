import Defaults
import Foundation

@MainActor
enum MessageImportReconciliationService {
	static func reconcile() async {
		guard SessionStore.shared.isAuthenticated else { return }
		var queued = Defaults[.pendingMessageTimetableLocators]
		if !Defaults[.pendingMessageTimetableIDs].isEmpty {
			queued.append(contentsOf: Defaults[.pendingMessageTimetableIDs])
			queued = Array(Set(queued))
			Defaults[.pendingMessageTimetableLocators] = queued
			Defaults[.pendingMessageTimetableIDs] = []
		}
		var remaining: [String] = []
		for value in queued {
			do {
				try await ReceivedTimetableSyncService.shared.importTimetable(locator: value)
			} catch {
				remaining.append(value)
			}
		}
		Defaults[.pendingMessageTimetableLocators] = remaining
		try? await ReceivedTimetableSyncService.shared.refreshAuthoritativeProjection()
	}
}
