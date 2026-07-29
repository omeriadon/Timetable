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
					Label {
						VStack(alignment: .leading, spacing: 4) {
							Text(entry.label)
								.foregroundStyle(.primary)
							Text(dateLabel(for: entry))
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: kind == "term" ? "calendar" : "calendar.badge.exclamationmark")
					}
					.padding(.vertical, 6)
				}
				.buttonStyle(.plain)
				.listRowInsets(.init(top: 2, leading: 20, bottom: 2, trailing: 20))
				.swipeActions {
					Button("Delete", systemImage: "trash", role: .destructive) {
						delete(entry.id)
					}
				}
			}

			Button(addButtonTitle, systemImage: "plus") {
				editor = newEntry()
			}
			.listRowInsets(.init(top: 2, leading: 20, bottom: 2, trailing: 20))
		}
		.listRowSpacing(8)
		.appNavigationTitle(navigationTitle, accent: true)
		.task {
			await load()
		}
		.refreshable {
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
		kind == "term" ? "Term Dates" : "Pupil Free Days"
	}

	private var addButtonTitle: String {
		kind == "term" ? "Add Term Date" : "Add Pupil Free Day"
	}

	private func dateLabel(for entry: AdministrationCalendarEntry) -> String {
		let start = shortDate(for: entry.startDate)

		guard kind == "term", let endDate = entry.endDate else {
			return start
		}

		return "\(start) – \(shortDate(for: endDate))"
	}

	private func shortDate(for calendarDate: SchoolCalendarDate) -> String {
		guard let date = calendarDate.startOfDay() else {
			return calendarDate.displayLabel
		}

		return date.formatted(.dateTime.day().month(.abbreviated).year())
	}
}
