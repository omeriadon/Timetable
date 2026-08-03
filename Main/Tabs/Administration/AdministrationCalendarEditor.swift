import SwiftUI

struct AdministrationCalendarEditor: View {
	let entry: AdministrationCalendarEntry
	let save: (AdministrationCalendarEntryRequest, UUID?) async throws -> Void
	let delete: (UUID) async throws -> Void
	let close: () -> Void
	let embedsInNavigation: Bool
	let showsCloseButton: Bool

	@State private var label: String
	@State private var start: Date
	@State private var end: Date

	init(
		entry: AdministrationCalendarEntry,
		save: @escaping (AdministrationCalendarEntryRequest, UUID?) async throws -> Void,
		delete: @escaping (UUID) async throws -> Void,
		close: @escaping () -> Void,
		embedsInNavigation: Bool = true,
		showsCloseButton: Bool = true
	) {
		self.entry = entry
		self.save = save
		self.delete = delete
		self.close = close
		self.embedsInNavigation = embedsInNavigation
		self.showsCloseButton = showsCloseButton
		_label = State(initialValue: entry.label)
		_start = State(initialValue: entry.startDate.startOfDay() ?? .now)
		_end = State(initialValue: entry.endDate?.startOfDay() ?? entry.startDate.startOfDay() ?? .now)
	}

	var body: some View {
		if embedsInNavigation {
			NavigationStack {
				content
			}
		} else {
			content
		}
	}

	private var content: some View {
		Form {
			TextField("Name", text: $label)
			DatePicker("Start", selection: $start, displayedComponents: .date)

			if entry.kind == "term" {
				DatePicker("End", selection: $end, displayedComponents: .date)
			}
		}
		.interactiveDismissDisabled()
		.appGroupedFormStyle()
		.appNavigationTitle(entry.kind == "term" ? "Term Date" : "Pupil Free Day", accent: true)
		.toolbar {
			if showsCloseButton {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						close()
					}
				}
			}

			ToolbarItem(placement: .confirmationAction) {
				Button("Save", systemImage: "checkmark", role: .confirm) {
					saveEntry()
				}
				.buttonStyle(.glassProminent)
			}
		}
		.safeAreaBar(edge: .bottom) {
			if !entry.label.isEmpty {
				Button("Delete", systemImage: "trash", role: .destructive) {
					deleteEntry()
				}
				.buttonStyle(.glassProminent)
				.tint(.red)
			}
		}
		.presentationDetents([.fraction(0.6)])
	}

	private func saveEntry() {
		let request = AdministrationCalendarEntryRequest(
			kind: entry.kind,
			label: label,
			startDate: SchoolCalendarDate(start),
			endDate: entry.kind == "term" ? SchoolCalendarDate(end) : nil
		)

		Task {
			try? await save(request, entry.label.isEmpty ? nil : entry.id)
			close()
		}
	}

	private func deleteEntry() {
		Task {
			try? await delete(entry.id)
			close()
		}
	}
}
