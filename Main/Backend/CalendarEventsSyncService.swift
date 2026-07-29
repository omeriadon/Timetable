import Defaults
import Foundation
import WidgetKit

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
		WidgetCenter.shared.reloadAllTimelines()
	}

	func createEvent(_ request: CreateCalendarEventRequest, globally: Bool) async throws {
		let response: CalendarEventsResponse = try await networkManager.send(
			globally ? .v1GlobalCalendarEvents : .v1PrivateCalendarEvents,
			body: globally
				? request
				: request.withSyncMetadata(id: UUID(), baseRevision: 0),
			context: .userInitiated
		)
		Defaults[.calendarEvents] = response.projection
		WidgetCenter.shared.reloadAllTimelines()
	}

	func deleteEvent(id: UUID, globally: Bool) async throws {
		let event = Defaults[.calendarEvents].allEvents.first {
			$0.id == id
		}
		let revisionQuery = globally
			? ""
			: "?baseRevision=\(event?.revision ?? 0)"
		let response: CalendarEventsResponse = try await networkManager.send(
			Endpoint(
				"/v1/events/\(globally ? "global" : "private")/\(id.uuidString)\(revisionQuery)",
				method: .delete
			),
			context: .userInitiated
		)
		Defaults[.calendarEvents] = response.projection
		WidgetCenter.shared.reloadAllTimelines()
	}

	func updateEvent(id: UUID, request: CreateCalendarEventRequest, globally: Bool) async throws {
		let event = Defaults[.calendarEvents].allEvents.first {
			$0.id == id
		}
		let response: CalendarEventsResponse = try await networkManager.send(
			Endpoint("/v1/events/\(globally ? "global" : "private")/\(id.uuidString)", method: .put),
			body: request.withSyncMetadata(
				id: id,
				baseRevision: event?.revision ?? 0
			),
			context: .userInitiated
		)
		Defaults[.calendarEvents] = response.projection
		WidgetCenter.shared.reloadAllTimelines()
	}
}

private extension Endpoint {
	static let v1CalendarEvents = Endpoint("/v1/events")
	static let v1GlobalCalendarEvents = Endpoint("/v1/events/global", method: .post)
	static let v1PrivateCalendarEvents = Endpoint("/v1/events/private", method: .post)
}
