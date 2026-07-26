import Defaults
import SwiftUI

struct AdministrationSchoolEventsView: View {
	@Default(.calendarEvents) private var events
	@State private var service = CalendarEventsSyncService.shared
	@State private var editorTarget: AdministrationSchoolEventEditorTarget?

	var body: some View {
		List {
			ForEach(events.globalEvents) { event in
				Button {
					editorTarget = .edit(event)
				} label: {
					Label {
						VStack(alignment: .leading, spacing: 4) {
							Text(event.title)
								.foregroundStyle(.primary)
							Text(event.date.displayLabel)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: event.symbol)
					}
					.padding(.vertical, 6)
				}
				.buttonStyle(.plain)
				.listRowInsets(.init(top: 2, leading: 20, bottom: 2, trailing: 20))
				.swipeActions {
					Button("Delete", systemImage: "trash", role: .destructive) {
						Task {
							try? await delete(event)
						}
					}
				}
			}

			Button("Add School Event", systemImage: "plus") {
				editorTarget = .create
			}
		}
		.listRowSpacing(8)
		.appNavigationTitle("School Events", accent: true)
		.sheet(item: $editorTarget) { target in
			AdministrationSchoolEventEditor(
				target: target,
				save: save,
				delete: delete
			)
			.presentationDetents([.fraction(0.6)])
		}
	}

	private func save(
		_ request: CreateCalendarEventRequest,
		existingEvent: CalendarEvent?
	) async throws {
		if let existingEvent {
			try await service.updateEvent(id: existingEvent.id, request: request, globally: true)
		} else {
			try await service.createEvent(request, globally: true)
		}
	}

	private func delete(_ event: CalendarEvent) async throws {
		try await service.deleteEvent(id: event.id, globally: true)
	}
}

enum AdministrationSchoolEventEditorTarget: Identifiable {
	case create
	case edit(CalendarEvent)

	var id: String {
		switch self {
			case .create:
				"create"
			case let .edit(event):
				event.id.uuidString
		}
	}

	var event: CalendarEvent? {
		if case let .edit(event) = self {
			return event
		}

		return nil
	}
}
