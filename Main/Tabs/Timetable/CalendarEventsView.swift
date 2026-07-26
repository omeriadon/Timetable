import Defaults
import SwiftUI

#if os(iOS)
	import SFSymbolsPicker
#endif

struct DatesView: View {
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.calendarEvents) private var events
	@State private var editorTarget: CalendarEventEditorTarget?
	@State private var eventService = CalendarEventsSyncService.shared
	@Environment(\.statusBadgeManager) private var badges
	@Namespace private var eventEditorNamespace

	private let calendar = SchoolCalendarProjection.perthCalendar

	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 16) {
				Text("Upcoming")
					.font(.title.bold())

				if timelineEntries.isEmpty {
					ContentUnavailableView(
						"No Upcoming Events",
						systemImage: "calendar",
						description: Text("Add a personal event or wait for the school calendar to update.")
					)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 36)
				} else {
					ForEach(timelineEntries) { entry in
						Section {
							timelineEntry(entry)
						}
						.foregroundStyle(.black)
						.background {
							GeometryReader { proxy in
								Image("paperWhite")
									.resizable()
									.scaledToFill()
									.frame(width: proxy.size.width, height: proxy.size.height)
									.clipped()
							}
							.clipShape(RoundedRectangle(cornerRadius: 20))
						}
					}
				}

				termDates
			}
			.padding()
		}

		.safeAreaBar(edge: .bottom, spacing: 10) {
			Button("Add Personal Event", systemImage: "plus") {
				editorTarget = .create(.privateEvent)
			}
			.controlSize(.extraLarge)
			.labelStyle(.iconOnly)
			.font(.title)
			.buttonBorderShape(.circle)
			.buttonStyle(.glassProminent)
			.matchedTransitionSource(id: "calendar-event-editor", in: eventEditorNamespace)
			.padding(.bottom, 10)
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
			.navigationTransition(.zoom(sourceID: "calendar-event-editor", in: eventEditorNamespace))
		}
	}

	private var termDates: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Term Dates")
				.font(.title2.bold())

			ForEach(Array(schoolCalendar.termRanges.enumerated()), id: \.offset) { _, range in
				if range.intersects(dateWindow) {
					timelineEntryContent(PlannerTimelineEntry(termRange: range))
				}
			}
		}
		.padding(.top, 20)
	}

	@ViewBuilder
	private func timelineEntry(_ entry: PlannerTimelineEntry) -> some View {
		if case let .event(event) = entry.kind {
			Button {
				editorTarget = .edit(event)
			} label: {
				timelineEntryContent(entry)
			}
			.buttonStyle(.plain)
		} else {
			timelineEntryContent(entry)
		}
	}

	private func timelineEntryContent(_ entry: PlannerTimelineEntry) -> some View {
		HStack(alignment: .center, spacing: 14) {
			Image(systemName: entry.symbol)
				.font(.title)
				.frame(width: 42)

			VStack(alignment: .leading, spacing: 4) {
				Text(entry.title)
					.font(.headline)

				if !entry.kind.title.isEmpty {
					Text(entry.kind.title)
						.font(.footnote)
				}

				if let notes = entry.notes, !notes.isEmpty {
					Text(notes)
						.font(.footnote)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)

			VStack(spacing: 2) {
				Text(entry.date.startOfDay()?.formatted(.dateTime.day()) ?? "")
					.font(.title2.bold())

				Text(entry.date.startOfDay()?.formatted(.dateTime.month(.abbreviated)) ?? "")
					.font(.caption.weight(.semibold))
			}
			.frame(width: 42)
		}
		.padding([.vertical, .leading])
		.padding(.trailing, 14)
		.foregroundStyle(entry.foregroundColor)
		.background(entry.backgroundColor, in: RoundedRectangle(cornerRadius: 20))
	}

	private var dateWindow: ClosedRange<SchoolCalendarDate> {
		let start = SchoolCalendarDate(TimetableClock.now, calendar: calendar)
		let end = SchoolCalendarDate(calendar.date(byAdding: .month, value: 3, to: TimetableClock.now) ?? TimetableClock.now, calendar: calendar)
		return start ... end
	}

	private var timelineEntries: [PlannerTimelineEntry] {
		let noSchoolEntries = schoolCalendar.skippedDates
			.filter { dateWindow.contains($0.date) }
			.map(PlannerTimelineEntry.init(noSchoolDay:))
		let eventEntries = (events.globalEvents + events.privateEvents)
			.filter { dateWindow.contains($0.date) }
			.map(PlannerTimelineEntry.init(event:))

		return (noSchoolEntries + eventEntries)
			.sorted {
				if $0.date == $1.date {
					return $0.title.localizedStandardCompare($1.title) == .orderedAscending
				}

				return $0.date < $1.date
			}
	}
}

private struct PlannerTimelineEntry: Identifiable {
	enum Kind {
		case noSchoolDay
		case termDate
		case event(CalendarEvent)

		var title: String {
			switch self {
				case .noSchoolDay:
					"Pupil Free Day"
				case .termDate:
					""
				case .event:
					""
			}
		}
	}

	let id: String
	let title: String
	let notes: String?
	let date: SchoolCalendarDate
	let symbol: String
	let kind: Kind

	var backgroundColor: Color {
		isPersonalEvent ? .white : .brown
	}

	var foregroundColor: Color {
		isPersonalEvent ? .black : .white
	}

	private var isPersonalEvent: Bool {
		if case let .event(event) = kind {
			return !event.isGlobal
		}

		return false
	}

	nonisolated init(noSchoolDay: SchoolCalendarNamedDate) {
		id = "no-school-\(noSchoolDay.date.year)-\(noSchoolDay.date.month)-\(noSchoolDay.date.day)"
		title = noSchoolDay.label
		notes = nil
		date = noSchoolDay.date
		symbol = "figure.wave"
		kind = .noSchoolDay
	}

	init(termRange: SchoolCalendarDateRange) {
		let termNumber = termRange.label
			.split(whereSeparator: { !$0.isNumber })
			.first
			.map(String.init)

		id = "term-\(termRange.start.year)-\(termRange.start.month)-\(termRange.start.day)-\(termRange.end.year)-\(termRange.end.month)-\(termRange.end.day)"
		title = termRange.label
		notes = termRange.displayLabel
		date = termRange.start
		symbol = if let termNumber {
			"\(termNumber).calendar"
		} else {
			"calendar"
		}
		kind = .termDate
	}

	nonisolated init(event: CalendarEvent) {
		id = event.id.uuidString
		title = event.title
		notes = event.notes
		date = event.date
		symbol = event.symbol
		kind = .event(event)
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

	private var isReadOnlyGlobalEvent: Bool {
		target.event?.isGlobal == true && !canManageGlobalEvents
	}

	private var navigationTitle: String {
		guard !isReadOnlyGlobalEvent else {
			return ""
		}

		return target.event == nil ? target.scope.title : "Edit Event"
	}

	var body: some View {
		NavigationStack {
			Form {
				if isReadOnlyGlobalEvent {
					readOnlyEventRows
				} else {
					TextField("Title", text: $title)
					TextField("Notes", text: $notes, axis: .vertical)
						.lineLimit(3 ... 6)
					DatePicker("Date", selection: $date, displayedComponents: .date)
					Button {
						showsSymbolPicker = true
					} label: {
						Label("Symbol", systemImage: symbol)
					}
				}
			}
			.appNavigationTitle(navigationTitle)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
					.disabled(isSaving)
				}
				if !isReadOnlyGlobalEvent {
					ToolbarItem(placement: .confirmationAction) {
						Button(target.event == nil ? "Add" : "Save", systemImage: target.event == nil ? "plus" : "checkmark", role: .confirm) {
							submit()
						}
						.buttonStyle(.glassProminent)
						.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
					}
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

	@ViewBuilder
	private var readOnlyEventRows: some View {
		HStack(spacing: 12) {
			Text(title)
				.font(.title3)
				.foregroundStyle(.primary)

			Spacer()

			Image(systemName: symbol)
				.font(.title3)
				.foregroundStyle(.accent)
				.padding(.trailing, 4)
		}

		if !notes.isEmpty {
			LabeledContent("Notes", value: notes)
		}

		LabeledContent("Date", value: date.formatted(date: .long, time: .omitted))
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
