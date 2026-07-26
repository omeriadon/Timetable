import SwiftUI

struct AdministrationSchoolEventEditor: View {
	let target: AdministrationSchoolEventEditorTarget
	let save: (CreateCalendarEventRequest, CalendarEvent?) async throws -> Void
	let delete: (CalendarEvent) async throws -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var title: String
	@State private var notes: String
	@State private var symbol: String
	@State private var date: Date
	@State private var showsSymbolPicker = false

	init(
		target: AdministrationSchoolEventEditorTarget,
		save: @escaping (CreateCalendarEventRequest, CalendarEvent?) async throws -> Void,
		delete: @escaping (CalendarEvent) async throws -> Void
	) {
		self.target = target
		self.save = save
		self.delete = delete
		_title = State(initialValue: target.event?.title ?? "")
		_notes = State(initialValue: target.event?.notes ?? "")
		_symbol = State(initialValue: target.event?.symbol ?? "calendar")
		_date = State(initialValue: target.event?.date.startOfDay() ?? TimetableClock.now)
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
			}
			.appNavigationTitle(target.event == nil ? "School Event" : "Edit School Event", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
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
		.sheet(isPresented: $showsSymbolPicker) {
			AdministrationEventSymbolPicker(symbol: $symbol)
		}
	}

	private func saveEvent() {
		let request = CreateCalendarEventRequest(
			title: title,
			notes: notes.isEmpty ? nil : notes,
			symbol: symbol,
			date: SchoolCalendarDate(date)
		)

		Task {
			try? await save(request, target.event)
			dismiss()
		}
	}

	private func deleteEvent(_ event: CalendarEvent) {
		Task {
			try? await delete(event)
			dismiss()
		}
	}
}
