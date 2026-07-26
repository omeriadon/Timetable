import SwiftUI

struct AdministrationCalendarEntriesView: View {
	let kind: String

	@State private var service = AdministrationService.shared
	@State private var entries: [AdministrationCalendarEntry] = []
	@State private var editor: AdministrationCalendarEntry?

	var body: some View {
		List {
			ForEach(entries) { entry in
				Button {
					editor = entry
				} label: {
					LabeledContent(entry.label) {
						Text(entry.startDate.displayLabel)
							.foregroundStyle(.secondary)
					}
				}
				.buttonStyle(.plain)
				.frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
				.listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
				.swipeActions {
					Button("Delete", systemImage: "trash", role: .destructive) {
						delete(entry.id)
					}
				}
			}

			Button(addButtonTitle, systemImage: "plus") {
				editor = newEntry()
			}
			.listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
		}
		.listRowSpacing(0)
		.appNavigationTitle(navigationTitle)
		.task {
			await load()
		}
		.sheet(item: $editor) { entry in
			AdministrationCalendarEditor(
				entry: entry,
				save: save,
				delete: deleteFromEditor
			)
		}
	}

	private func load() async {
		entries = await (try? service.calendar())?.filter { $0.kind == kind } ?? []
	}

	private func save(
		_ request: AdministrationCalendarEntryRequest,
		existingID: UUID?
	) async throws {
		let allEntries = try await service.save(request, id: existingID)
		entries = allEntries.filter { $0.kind == kind }
		try await SchoolCalendarSyncService.shared.downloadCalendar()
	}

	private func delete(_ id: UUID) {
		Task {
			try? await deleteFromEditor(id)
		}
	}

	private func deleteFromEditor(_ id: UUID) async throws {
		let allEntries = try await service.delete(id: id)
		entries = allEntries.filter { $0.kind == kind }
		try await SchoolCalendarSyncService.shared.downloadCalendar()
	}

	private func newEntry() -> AdministrationCalendarEntry {
		AdministrationCalendarEntry(
			id: UUID(),
			kind: kind,
			label: "",
			startDate: SchoolCalendarDate(TimetableClock.now),
			endDate: kind == "term" ? SchoolCalendarDate(TimetableClock.now) : nil
		)
	}

	private var navigationTitle: String {
		kind == "term" ? "Term Dates" : "No-School Days"
	}

	private var addButtonTitle: String {
		kind == "term" ? "Add Term Date" : "Add No-School Day"
	}
}
