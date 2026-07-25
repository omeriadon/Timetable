import Defaults
import Foundation
import WidgetKit

@MainActor
final class SchoolCalendarSyncService {
	static let shared = SchoolCalendarSyncService(networkManager: .shared)

	private let networkManager: NetworkManager

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func downloadCalendar() async throws {
		let response: SchoolCalendarResponse = try await networkManager.send(.v1SchoolCalendar)
		Defaults[.schoolCalendar] = response.projection
		Defaults[.lastServerSync] = .now
		WidgetCenter.shared.reloadAllTimelines()
	}
}

private extension Endpoint {
	static let v1SchoolCalendar = Endpoint("/v1/settings/calendar")
}
