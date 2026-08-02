import SwiftUI

struct AdministrationSchoolEventEditor: View {
	let target: AdministrationSchoolEventEditorTarget
	let save: (CreateCalendarEventRequest, CalendarEvent?) async throws -> Void
	let delete: (CalendarEvent) async throws -> Void
	let close: () -> Void

	@State private var title: String
	@State private var notes: String
	@State private var symbol: String
	@State private var date: Date
	@State private var showsSymbolPicker = false
	@State private var administrationService = AdministrationService.shared
	@State private var tagSections: [AdministrationEventTagSection] = []
	@State private var selectedTagIDs: Set<UUID>

	init(
		target: AdministrationSchoolEventEditorTarget,
		save: @escaping (CreateCalendarEventRequest, CalendarEvent?) async throws -> Void,
		delete: @escaping (CalendarEvent) async throws -> Void,
		close: @escaping () -> Void
	) {
		self.target = target
		self.save = save
		self.delete = delete
		self.close = close
		_title = State(initialValue: target.event?.title ?? "")
		_notes = State(initialValue: target.event?.notes ?? "")
		_symbol = State(initialValue: target.event?.symbol ?? "calendar")
		_date = State(initialValue: target.event?.date.startOfDay() ?? TimetableClock.now)
		_selectedTagIDs = State(initialValue: Set(target.event?.tagIDs ?? []))
	}

	var body: some View {
		NavigationStack {
			Form {
				TextField("Title", text: $title)
				TextField("Notes", text: $notes, axis: .vertical)
					.lineLimit(3 ... 6)
				DatePicker("Date", selection: $date, displayedComponents: .date)

				Button {
					showsSymbolPicker = true
				} label: {
					Label("Symbol", systemImage: symbol)
				}

				ForEach(tagSections) { section in
					Section(section.displayName) {
						ForEach(section.tags.filter { !$0.isArchived }) { tag in
							Toggle(
								tag.displayName,
								isOn: Binding(
									get: { selectedTagIDs.contains(tag.id) },
									set: { isSelected in
										if isSelected {
											selectedTagIDs.insert(tag.id)
										} else {
											selectedTagIDs.remove(tag.id)
										}
									}
								)
							)
						}
					}
				}
			}
			.appNavigationTitle(target.event == nil ? "School Event" : "Edit School Event", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						close()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button(target.event == nil ? "Add" : "Save", systemImage: target.event == nil ? "plus" : "checkmark", role: .confirm) {
						saveEvent()
					}
					.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					.buttonStyle(.glassProminent)
				}
			}
			.safeAreaBar(edge: .bottom) {
				if let event = target.event {
					Button("Delete Event", systemImage: "trash", role: .destructive) {
						deleteEvent(event)
					}
					.buttonStyle(.glassProminent)
					.tint(.red)
				}
			}
		}
		.interactiveDismissDisabled()
		.task {
			guard let catalogue = try? await administrationService.eventTags() else {
				return
			}

			tagSections = catalogue.sections.filter { !$0.isArchived }
		}
		.sheet(isPresented: $showsSymbolPicker) {
			AdministrationEventSymbolPicker(symbol: $symbol)
		}
	}

	private func saveEvent() {
		let request = CreateCalendarEventRequest(
			title: title,
			notes: notes.isEmpty ? nil : notes,
			symbol: symbol,
			date: SchoolCalendarDate(date),
			tagIDs: Array(selectedTagIDs)
		)

		Task {
			try? await save(request, target.event)
			close()
		}
	}

	private func deleteEvent(_ event: CalendarEvent) {
		Task {
			try? await delete(event)
			close()
		}
	}
}
