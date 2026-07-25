import Defaults
import Foundation

@MainActor
final class CalendarEventsSyncService {
	static let shared = CalendarEventsSyncService(networkManager: .shared)

	private let networkManager: NetworkManager

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func downloadEvents() async throws {
		let response: CalendarEventsResponse = try await networkManager.send(.v1CalendarEvents)
		Defaults[.calendarEvents] = response.projection
		Defaults[.lastServerSync] = .now
	}

	func createEvent(_ request: CreateCalendarEventRequest, globally: Bool) async throws {
		let response: CalendarEventsResponse = try await networkManager.send(
			globally ? .v1GlobalCalendarEvents : .v1PrivateCalendarEvents,
			body: request,
			context: .userInitiated
		)
		Defaults[.calendarEvents] = response.projection
	}

	func deleteEvent(id: UUID, globally: Bool) async throws {
		let response: CalendarEventsResponse = try await networkManager.send(
			Endpoint("/v1/events/\(globally ? "global" : "private")/\(id.uuidString)", method: .delete),
			context: .userInitiated
		)
		Defaults[.calendarEvents] = response.projection
	}
}

private extension Endpoint {
	static let v1CalendarEvents = Endpoint("/v1/events")
	static let v1GlobalCalendarEvents = Endpoint("/v1/events/global", method: .post)
	static let v1PrivateCalendarEvents = Endpoint("/v1/events/private", method: .post)
}
