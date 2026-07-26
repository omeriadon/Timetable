import SwiftUI

struct AdministrationCalendarEditor: View {
	let entry: AdministrationCalendarEntry
	let save: (AdministrationCalendarEntryRequest, UUID?) async throws -> Void
	let delete: (UUID) async throws -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var label: String
	@State private var start: Date
	@State private var end: Date

	init(
		entry: AdministrationCalendarEntry,
		save: @escaping (AdministrationCalendarEntryRequest, UUID?) async throws -> Void,
		delete: @escaping (UUID) async throws -> Void
	) {
		self.entry = entry
		self.save = save
		self.delete = delete
		_label = State(initialValue: entry.label)
		_start = State(initialValue: entry.startDate.startOfDay() ?? .now)
		_end = State(initialValue: entry.endDate?.startOfDay() ?? entry.startDate.startOfDay() ?? .now)
	}

	var body: some View {
		NavigationStack {
			Form {
				TextField("Name", text: $label)
				DatePicker("Start", selection: $start, displayedComponents: .date)

				if entry.kind == "term" {
					DatePicker("End", selection: $end, displayedComponents: .date)
				}
			}
			.appNavigationTitle(entry.kind == "term" ? "Term Date" : "No-School Day")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
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
			dismiss()
		}
	}

	private func deleteEntry() {
		Task {
			try? await delete(entry.id)
			dismiss()
		}
	}
}
