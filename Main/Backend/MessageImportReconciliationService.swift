import Defaults
import Foundation

@MainActor
enum MessageImportReconciliationService {
	static func reconcile() async {
		guard SessionStore.shared.isAuthenticated else { return }
		let queued = Defaults[.pendingMessageTimetableIDs]
		var remaining: [String] = []
		for value in queued {
			guard let id = UUID(uuidString: value) else { continue }
			do {
				try await ReceivedTimetableSyncService.shared.importTimetable(id: id)
			} catch {
				remaining.append(value)
			}
		}
		Defaults[.pendingMessageTimetableIDs] = remaining
		try? await ReceivedTimetableSyncService.shared.refreshAuthoritativeProjection()
	}
}
