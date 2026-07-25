import Defaults
import SwiftUI

#if os(iOS)
	import SFSymbolsPicker
#endif

struct CalendarEventsView: View {
	let projection: CalendarEventsProjection
	@State private var editorScope: CalendarEventScope?
	@State private var eventService = CalendarEventsSyncService.shared
	@Environment(\.statusBadgeManager) private var badges

	private let calendar = SchoolCalendarProjection.perthCalendar

	var body: some View {
		List {
			Section("School Events") {
				eventRows(projection.globalEvents)
			}

			Section("Your Events") {
				eventRows(projection.privateEvents)
				Button("Add Personal Event", systemImage: "plus") { editorScope = .privateEvent }
			}

			if projection.canManageGlobalEvents {
				Section("School Administration") {
					Button("Add School Event", systemImage: "plus") { editorScope = .globalEvent }
				}
			}
		}
		.appNavigationTitle("Events", style: .main)
		.sheet(item: $editorScope) { scope in
			CalendarEventEditor(scope: scope) { request in
				try await eventService.createEvent(request, globally: scope == .globalEvent)
			}
		}
	}

	@ViewBuilder
	private func eventRows(_ events: [CalendarEvent]) -> some View {
		let filtered = events.filter { dateWindow.contains($0.date) }.sorted { $0.date < $1.date }
		if filtered.isEmpty {
			Text("No events in the next three months.")
				.foregroundStyle(.secondary)
		} else {
			ForEach(filtered) { event in
				VStack(alignment: .leading, spacing: 4) {
					Label(event.title, systemImage: event.symbol)
					Text(event.date.displayLabel)
						.font(.footnote)
						.foregroundStyle(.secondary)
					if let notes = event.notes, !notes.isEmpty {
						Text(notes)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
				.swipeActions {
					if !event.isGlobal || projection.canManageGlobalEvents {
						Button("Delete", systemImage: "trash", role: .destructive) {
							Task {
								do { try await eventService.deleteEvent(id: event.id, globally: event.isGlobal) }
								catch { badges.addBadge(id: UUID(), title: "Unable to delete event", secondaryText: error.localizedDescription, priority: 4, view: .error) }
							}
						}
					}
				}
			}
		}
	}

	private var dateWindow: ClosedRange<SchoolCalendarDate> {
		let start = SchoolCalendarDate(TimetableClock.now, calendar: calendar)
		let end = SchoolCalendarDate(calendar.date(byAdding: .month, value: 3, to: TimetableClock.now) ?? TimetableClock.now, calendar: calendar)
		return start ... end
	}
}

private enum CalendarEventScope: String, Identifiable {
	case privateEvent
	case globalEvent
	var id: String {
		rawValue
	}

	var title: String {
		self == .globalEvent ? "School Event" : "Personal Event"
	}
}

private struct CalendarEventEditor: View {
	let scope: CalendarEventScope
	let save: (CreateCalendarEventRequest) async throws -> Void
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges
	@State private var title = ""
	@State private var notes = ""
	@State private var symbol = "calendar"
	@State private var date = TimetableClock.now
	@State private var isSaving = false
	@State private var showsSymbolPicker = false

	var body: some View {
		NavigationStack {
			Form {
				TextField("Title", text: $title)
				TextField("Notes", text: $notes, axis: .vertical)
					.lineLimit(3 ... 6)
				DatePicker("Date", selection: $date, displayedComponents: .date)
				Button { showsSymbolPicker = true } label: { Label("Symbol", systemImage: symbol) }
			}
			.appNavigationTitle(scope.title)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(isSaving) }
				ToolbarItem(placement: .confirmationAction) {
					Button("Add") { submit() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
			}
		}
		.sheet(isPresented: $showsSymbolPicker) { CalendarEventSymbolPicker(symbol: $symbol) }
	}

	private func submit() {
		isSaving = true
		let request = CreateCalendarEventRequest(title: title, notes: notes.isEmpty ? nil : notes, symbol: symbol, date: SchoolCalendarDate(date))
		Task {
			do { try await save(request); dismiss() }
			catch { isSaving = false; badges.addBadge(id: UUID(), title: "Unable to save event", secondaryText: error.localizedDescription, priority: 4, view: .error) }
		}
	}
}

private struct CalendarEventSymbolPicker: View {
	@Binding var symbol: String
	#if os(iOS)
		@Environment(\.dismiss) private var dismiss
	#endif
	var body: some View {
		#if os(iOS)
			SymbolsPicker(selection: $symbol, title: "", searchLabel: "Search symbols...", autoDismiss: true)
		#else
			Form { TextField("SF Symbol name", text: $symbol); Label("Preview", systemImage: symbol) }.padding()
		#endif
	}
}
