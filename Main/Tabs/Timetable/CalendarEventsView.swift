import Defaults
import SwiftUI

#if os(iOS)
	import SFSymbolsPicker
#endif

struct DatesView: View {
	let schoolCalendar: SchoolCalendarProjection
	let events: CalendarEventsProjection
	@State private var editorTarget: CalendarEventEditorTarget?
	@State private var eventService = CalendarEventsSyncService.shared
	@Environment(\.statusBadgeManager) private var badges

	private let calendar = SchoolCalendarProjection.perthCalendar

	var body: some View {
		List {
			Section("Term Dates") {
				ForEach(Array(schoolCalendar.termRanges.enumerated()), id: \.offset) { _, range in
					if range.intersects(dateWindow) {
						LabeledContent(range.label) { Text(range.displayLabel).foregroundStyle(.secondary) }
					}
				}
			}
			Section("No School") {
				ForEach(schoolCalendar.skippedDates.filter { dateWindow.contains($0.date) }.sorted { $0.date < $1.date }, id: \.self) { date in
					LabeledContent(date.label) { Text(date.date.displayLabel).foregroundStyle(.secondary) }
				}
			}
			Section("School Events") {
				eventRows(events.globalEvents)
			}

			Section("Your Events") {
				eventRows(events.privateEvents)
				Button("Add Personal Event", systemImage: "plus") { editorTarget = .create(.privateEvent) }
			}

			if events.canManageGlobalEvents {
				Section("School Administration") {
					Button("Add School Event", systemImage: "plus") { editorTarget = .create(.globalEvent) }
				}
			}
		}
		.sheet(item: $editorTarget) { target in
			CalendarEventEditor(target: target, canManageGlobalEvents: events.canManageGlobalEvents) { request, event in
				if let event {
					try await eventService.updateEvent(id: event.id, request: request, globally: event.isGlobal)
				} else {
					try await eventService.createEvent(request, globally: target.scope == .globalEvent)
				}
			} delete: { event in
				try await eventService.deleteEvent(id: event.id, globally: event.isGlobal)
			}
			.presentationDetents([.fraction(0.6)])
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
				Button { editorTarget = .edit(event) } label: { HStack(alignment: .center) {
					Image(systemName: event.symbol)
						.font(.largeTitle.scaled(by: 1.2))
						.padding(.trailing, 5)
						.foregroundStyle(.accent)

					VStack(alignment: .leading, spacing: 4) {
						Text(event.title)

						Text(event.date.displayLabel)
							.font(.footnote)
							.foregroundStyle(.secondary)

						if let notes = event.notes, !notes.isEmpty {
							Text(notes)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
				} }
				.buttonStyle(.plain)
			}
		}
	}

	private var dateWindow: ClosedRange<SchoolCalendarDate> {
		let start = SchoolCalendarDate(TimetableClock.now, calendar: calendar)
		let end = SchoolCalendarDate(calendar.date(byAdding: .month, value: 3, to: TimetableClock.now) ?? TimetableClock.now, calendar: calendar)
		return start ... end
	}
}

private enum CalendarEventEditorTarget: Identifiable {
	case create(CalendarEventScope)
	case edit(CalendarEvent)
	var id: String {
		switch self { case let .create(scope): "create-\(scope.id)"; case let .edit(event): event.id.uuidString }
	}

	var scope: CalendarEventScope {
		switch self { case let .create(scope): scope; case let .edit(event): event.isGlobal ? .globalEvent : .privateEvent }
	}

	var event: CalendarEvent? {
		if case let .edit(event) = self {
			event
		} else {
			nil
		}
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
	let target: CalendarEventEditorTarget
	let canManageGlobalEvents: Bool
	let save: (CreateCalendarEventRequest, CalendarEvent?) async throws -> Void
	let delete: (CalendarEvent) async throws -> Void
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges
	@State private var title: String
	@State private var notes: String
	@State private var symbol: String
	@State private var date: Date
	@State private var isSaving = false
	@State private var showsSymbolPicker = false

	init(target: CalendarEventEditorTarget, canManageGlobalEvents: Bool, save: @escaping (CreateCalendarEventRequest, CalendarEvent?) async throws -> Void, delete: @escaping (CalendarEvent) async throws -> Void) {
		self.target = target
		self.canManageGlobalEvents = canManageGlobalEvents
		self.save = save
		self.delete = delete
		let event = target.event
		_title = State(initialValue: event?.title ?? "")
		_notes = State(initialValue: event?.notes ?? "")
		_symbol = State(initialValue: event?.symbol ?? "calendar")
		_date = State(initialValue: event?.date.startOfDay() ?? TimetableClock.now)
	}

	var body: some View {
		NavigationStack {
			Form {
				TextField("Title", text: $title)
				TextField("Notes", text: $notes, axis: .vertical)
					.lineLimit(3 ... 6)
				DatePicker("Date", selection: $date, displayedComponents: .date)
				Button { showsSymbolPicker = true } label: { Label("Symbol", systemImage: symbol) }
			}
			.disabled(target.event?.isGlobal == true && !canManageGlobalEvents)
			.appNavigationTitle(target.event == nil ? target.scope.title : "Edit Event")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
					.disabled(isSaving)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(target.event == nil ? "Add" : "Save", systemImage: target.event == nil ? "plus" : "checkmark", role: .confirm) {
						submit()
					}
					.buttonStyle(.glassProminent)
					.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
			}
		}
		.safeAreaBar(edge: .bottom) {
			if let event = target.event, !event.isGlobal || canManageGlobalEvents {
				Button("Delete Event", systemImage: "trash", role: .destructive) {
					deleteEvent(event)
				}
				.buttonStyle(.glassProminent)
				.tint(.red)
			}
		}
		.sheet(isPresented: $showsSymbolPicker) { CalendarEventSymbolPicker(symbol: $symbol) }
	}

	private func submit() {
		isSaving = true
		let request = CreateCalendarEventRequest(title: title, notes: notes.isEmpty ? nil : notes, symbol: symbol, date: SchoolCalendarDate(date))
		Task {
			do { try await save(request, target.event); dismiss() }
			catch { isSaving = false; badges.addBadge(id: UUID(), title: "Unable to save event", secondaryText: error.localizedDescription, priority: 4, view: .error) }
		}
	}

	private func deleteEvent(_ event: CalendarEvent) {
		Task { do { try await delete(event); dismiss() } catch { badges.addBadge(id: UUID(), title: "Unable to delete event", secondaryText: error.localizedDescription, priority: 4, view: .error) } }
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

private extension SchoolCalendarDateRange {
	func intersects(_ window: ClosedRange<SchoolCalendarDate>) -> Bool {
		start <= window.upperBound && end >= window.lowerBound
	}

	var displayLabel: String {
		guard let startDate = start.startOfDay(), let endDate = end.startOfDay() else { return "" }
		return "\(startDate.formatted(.dateTime.day().month(.abbreviated))) – \(endDate.formatted(.dateTime.day().month(.abbreviated).year()))"
	}
}
