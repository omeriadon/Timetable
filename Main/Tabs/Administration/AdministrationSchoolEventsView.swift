import Defaults
import SwiftUI

struct AdministrationSchoolEventsView: View {
	let closeWideDestination: (() -> Void)?
	@Default(.calendarEvents) private var events
	@State private var service = CalendarEventsSyncService.shared
	@State private var editorTarget: CalendarEventEditorTarget?
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation

	var body: some View {
		List {
			ForEach(events.globalEvents) { event in
				eventLink(event)
					.listRowInsets(.init(top: 2, leading: 20, bottom: 2, trailing: 20))
					.swipeActions {
						Button("Delete", systemImage: "trash", role: .destructive) {
							Task {
								try? await delete(event)
							}
						}
					}
			}

			addEventLink
		}
		.appNavigationTitle("School Events", accent: true)
		.refreshable {
			await refreshEvents()
		}
		.sheet(item: $editorTarget) { target in
			CalendarEventEditor(
				target: target,
				canManageGlobalEvents: true,
				close: { editorTarget = nil },
				save: save,
				delete: delete
			)
			.presentationDetents([.fraction(0.7)])
		}
	}

	@ViewBuilder
	private func eventLink(_ event: CalendarEvent) -> some View {
		if presentation == .iOS {
			Button {
				editorTarget = .edit(event)
			} label: {
				eventLabel(event)
			}
			.buttonStyle(.plain)
		} else {
			NavigationLink {
				CalendarEventEditor(
					target: .edit(event),
					canManageGlobalEvents: true,
					close: closeWideEditor,
					save: save,
					delete: delete,
					embedsInNavigation: false
				)
			} label: {
				eventLabel(event)
			}
		}
	}

	@ViewBuilder
	private var addEventLink: some View {
		if presentation == .iOS {
			Button("Add School Event", systemImage: "plus") {
				editorTarget = .create(.globalEvent)
			}
		} else {
			NavigationLink {
				CalendarEventEditor(
					target: .create(.globalEvent),
					canManageGlobalEvents: true,
					close: closeWideEditor,
					save: save,
					delete: delete,
					embedsInNavigation: false
				)
			} label: {
				Label("Add School Event", systemImage: "plus")
			}
		}
	}

	private func closeWideEditor() {
		closeWideDestination?()
	}

	private func eventLabel(_ event: CalendarEvent) -> some View {
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

	private func refreshEvents() async {
		do {
			try await service.downloadEvents()
		} catch {
			badges.present(error: error, title: "Unable to refresh school events")
		}
	}

	private func delete(_ event: CalendarEvent) async throws {
		try await service.deleteEvent(id: event.id, globally: true)
	}
}
