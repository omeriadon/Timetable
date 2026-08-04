import SwiftUI

struct AdministrationCalendarEntriesView: View {
	let kind: String
	let closeWideDestination: (() -> Void)?

	@State private var service = AdministrationService.shared
	@State private var entries: [AdministrationCalendarEntry] = []
	@State private var editor: AdministrationCalendarEntry?
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation

	var body: some View {
		List {
			ForEach(entries) { entry in
				entryLink(entry)
					.buttonStyle(.plain)
					.listRowInsets(.init(top: 2, leading: 20, bottom: 2, trailing: 20))
					.swipeActions {
						Button("Delete", systemImage: "trash", role: .destructive) {
							delete(entry.id)
						}
					}
			}

			addEntryLink
				.listRowInsets(.init(top: 2, leading: 20, bottom: 2, trailing: 20))
		}
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
				delete: deleteFromEditor,
				close: { editor = nil }
			)
		}
	}

	@ViewBuilder
	private func entryLink(_ entry: AdministrationCalendarEntry) -> some View {
		if presentation == .iOS {
			Button {
				editor = entry
			} label: {
				entryLabel(entry)
			}
		} else {
			NavigationLink {
				AdministrationCalendarEditor(
					entry: entry,
					save: save,
					delete: deleteFromEditor,
					close: closeWideEditor,
					embedsInNavigation: false,
					showsCloseButton: false
				)
			} label: {
				entryLabel(entry)
			}
		}
	}

	private func entryLabel(_ entry: AdministrationCalendarEntry) -> some View {
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

	@ViewBuilder
	private var addEntryLink: some View {
		if presentation == .iOS {
			Button(addButtonTitle, systemImage: "plus") {
				editor = newEntry()
			}
		} else {
			NavigationLink {
				AdministrationCalendarEditor(
					entry: newEntry(),
					save: save,
					delete: deleteFromEditor,
					close: closeWideEditor,
					embedsInNavigation: false,
					showsCloseButton: false
				)
			} label: {
				Label(addButtonTitle, systemImage: "plus")
			}
		}
	}

	private func closeWideEditor() {
		closeWideDestination?()
	}

	private func load() async {
		do {
			let calendarEntries = try await service.calendar()
			entries = calendarEntries.filter { $0.kind == kind }
		} catch {
			badges.present(error: error, title: "Unable to refresh calendar entries")
		}
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
