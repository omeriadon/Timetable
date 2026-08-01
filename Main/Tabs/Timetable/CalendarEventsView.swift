import Defaults
import SwiftUI

#if os(iOS)
	import SFSymbolsPicker
#endif

struct DatesView: View {
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.calendarEvents) private var events
	@State private var presentationTarget: PlannerPresentationTarget?
	@State private var eventService = CalendarEventsSyncService.shared
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@Namespace private var eventEditorNamespace

	private let calendar = SchoolCalendarProjection.perthCalendar

	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
				Section {
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
							animatedScrollCard(timelineEntry(entry))
						}
					}
				} header: {
					plannerSectionHeader("Upcoming")
				}

				Section {
					termDateCards
				} header: {
					plannerSectionHeader("Term Dates")
				}
			}
			.padding()
		}

		.safeAreaBar(edge: .bottom, spacing: 10) {
			Button {
				presentationTarget = .createEvent(.privateEvent)
			} label: {
				Label("Add Personal Event", systemImage: "plus")
					.font(.largeTitle)
					.bold()
					.padding(5)
			}
			.controlSize(.extraLarge)
			.labelStyle(.iconOnly)
			.buttonBorderShape(.circle)
			.buttonStyle(.glassProminent)
			.matchedTransitionSource(
				id: PlannerPresentationTarget.createEvent(.privateEvent).transitionID,
				in: eventEditorNamespace
			)
			.padding(.bottom, 15)
		}
		.sheet(item: $presentationTarget) { target in
			plannerPresentation(for: target)
		}
	}

	@ViewBuilder
	private func plannerPresentation(for target: PlannerPresentationTarget) -> some View {
		switch target {
			case let .createEvent(scope):
				calendarEventEditor(
					target: .create(scope),
					transitionID: target.transitionID
				)
			case let .calendarEvent(event, _):
				calendarEventEditor(
					target: .edit(event),
					transitionID: target.transitionID
				)
			case let .noSchoolDay(detail):
				NoSchoolDayDetailView(target: detail)
					.presentationDetents([.fraction(0.5)])
					.navigationTransition(.zoom(sourceID: target.transitionID, in: eventEditorNamespace))
		}
	}

	private func calendarEventEditor(
		target: CalendarEventEditorTarget,
		transitionID: String
	) -> some View {
		CalendarEventEditor(
			target: target,
			canManageGlobalEvents: events.canManageGlobalEvents
		) { request, event in
			if let event {
				try await eventService.updateEvent(
					id: event.id,
					request: request,
					globally: event.isGlobal
				)
			} else {
				try await eventService.createEvent(
					request,
					globally: target.scope == .globalEvent
				)
			}
		} delete: { event in
			try await eventService.deleteEvent(
				id: event.id,
				globally: event.isGlobal
			)
		}
		.presentationDetents([.fraction(0.6)])
		.navigationTransition(.zoom(sourceID: transitionID, in: eventEditorNamespace))
	}

	private var termDateCards: some View {
		ForEach(Array(schoolCalendar.termRanges.enumerated()), id: \.offset) { _, range in
			if range.intersects(dateWindow) {
				animatedScrollCard(
					timelineEntryContent(PlannerTimelineEntry(termRange: range))
				)
			}
		}
	}

	private func plannerSectionHeader(_ title: String) -> some View {
		Text(title)
			.font(.title.bold())
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.vertical, 6)
			.zIndex(2)
	}

	@ViewBuilder
	private func timelineEntry(_ entry: PlannerTimelineEntry) -> some View {
		if let target = PlannerPresentationTarget(entry: entry) {
			Button {
				presentationTarget = target
			} label: {
				timelineEntryContent(entry)
			}
			.buttonStyle(.plain)
			.frame(maxWidth: .infinity)
			.matchedTransitionSource(id: target.transitionID, in: eventEditorNamespace)
			.contentShape(RoundedRectangle(cornerRadius: 20))
		} else {
			timelineEntryContent(entry)
		}
	}

	private func animatedScrollCard(_ content: some View) -> some View {
		let shouldReduceMotion = reduceMotion

		return content
			.scrollTransition(.animated(.snappy(duration: 0.3))) { card, phase in
				card
					.opacity(shouldReduceMotion || phase.isIdentity ? 1 : 0.65)
					.scaleEffect(shouldReduceMotion || phase.isIdentity ? 1 : 0.96)
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
		.background {
			GeometryReader { proxy in
				Image(entry.backgroundImageName)
					.resizable()
					.scaledToFill()
					.frame(width: proxy.size.width, height: proxy.size.height)
					.clipped()
			}
			.clipShape(RoundedRectangle(cornerRadius: 20))
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 20))
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
		let globalEventEntries = events.globalEvents
			.enumerated()
			.filter { dateWindow.contains($0.element.date) }
			.map { entry in
				PlannerTimelineEntry(event: entry.element, occurrence: entry.offset)
			}
		let privateEventEntries = events.privateEvents
			.enumerated()
			.filter { dateWindow.contains($0.element.date) }
			.map { entry in
				PlannerTimelineEntry(event: entry.element, occurrence: entry.offset)
			}

		return (noSchoolEntries + globalEventEntries + privateEventEntries)
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

	var backgroundImageName: String {
		isPersonalEvent ? "paperWhite" : "paper"
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

	nonisolated init(event: CalendarEvent, occurrence: Int) {
		let scope = event.isGlobal ? "global" : "personal"
		id = "event-\(scope)-\(event.date.year)-\(event.date.month)-\(event.date.day)-\(event.id.uuidString)-\(occurrence)"
		title = event.title
		notes = event.notes
		date = event.date
		symbol = event.symbol
		kind = .event(event)
	}
}

private enum PlannerPresentationTarget: Identifiable {
	case createEvent(CalendarEventScope)
	case calendarEvent(CalendarEvent, entryID: String)
	case noSchoolDay(NoSchoolDayDetailTarget)

	init?(entry: PlannerTimelineEntry) {
		switch entry.kind {
			case let .event(event):
				self = .calendarEvent(event, entryID: entry.id)
			case .noSchoolDay:
				self = .noSchoolDay(NoSchoolDayDetailTarget(entry: entry))
			case .termDate:
				return nil
		}
	}

	var id: String {
		switch self {
			case let .createEvent(scope):
				"create-event-\(scope.id)"
			case let .calendarEvent(_, entryID):
				"calendar-event-\(entryID)"
			case let .noSchoolDay(detail):
				"no-school-day-\(detail.id)"
		}
	}

	var transitionID: String {
		"planner-presentation-\(id)"
	}
}

private enum CalendarEventEditorTarget {
	case create(CalendarEventScope)
	case edit(CalendarEvent)

	var scope: CalendarEventScope {
		switch self {
			case let .create(scope):
				scope
			case let .edit(event):
				event.isGlobal ? .globalEvent : .privateEvent
		}
	}

	var event: CalendarEvent? {
		if case let .edit(event) = self {
			event
		} else {
			nil
		}
	}
}

private struct NoSchoolDayDetailTarget: Identifiable {
	let id: String
	let title: String
	let date: SchoolCalendarDate

	init(entry: PlannerTimelineEntry) {
		id = entry.id
		title = entry.title
		date = entry.date
	}
}

private struct NoSchoolDayDetailView: View {
	let target: NoSchoolDayDetailTarget
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			Form {
				LabeledContent("Name", value: target.title)
				LabeledContent(
					"Date",
					value: target.date.startOfDay()?.formatted(date: .long, time: .omitted) ?? ""
				)
			}
			.appNavigationTitle("Pupil Free Day")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}
			}
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
	@State private var administrationService = AdministrationService.shared
	@State private var tagSections: [EventTagCatalogueSection] = []
	@State private var selectedTagIDs: Set<UUID>

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
		_selectedTagIDs = State(initialValue: Set(event?.tagIDs ?? []))
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

					EventTagSelector(
						sections: tagSections,
						allowsYearGroups: target.scope == .globalEvent,
						selectedTagIDs: $selectedTagIDs
					)
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
		.task {
			guard let catalogue = try? await administrationService.tagCatalogue() else {
				return
			}

			tagSections = catalogue.sections
		}
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
		let request = CreateCalendarEventRequest(
			title: title,
			notes: notes.isEmpty ? nil : notes,
			symbol: symbol,
			date: SchoolCalendarDate(date),
			tagIDs: Array(selectedTagIDs)
		)
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
			ContentUnavailableView(
				"Symbol Picker Unavailable",
				systemImage: symbol,
				description: Text("SF Symbols can be selected on iPhone and iPad.")
			)
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
