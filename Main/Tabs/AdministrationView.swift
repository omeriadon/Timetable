import Defaults
import SwiftUI

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false
	@State private var users: [AdministrationUserResponse] = []
	@State private var entries: [AdministrationCalendarEntry] = []
	@State private var searchText = ""
	@State private var editor: AdministrationCalendarEntry?
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		NavigationStack {
			Group {
				if isAdmin {
					List {
						Section("Global Events") {
							NavigationLink("Manage Global Events", systemImage: "calendar") { AdministrationGlobalEventsView() }
						}
						Section("School Calendar") {
							ForEach(entries) { entry in
								Button { editor = entry } label: { LabeledContent(entry.label) { Text(entry.kind == "term" ? "Term" : "No School").foregroundStyle(.secondary) } }.buttonStyle(.plain)
							}
							Button("Add Term Date", systemImage: "plus") { editor = AdministrationCalendarEntry(id: UUID(), kind: "term", label: "", startDate: SchoolCalendarDate(TimetableClock.now), endDate: SchoolCalendarDate(TimetableClock.now)) }
							Button("Add No-School Day", systemImage: "plus") { editor = AdministrationCalendarEntry(id: UUID(), kind: "noSchool", label: "", startDate: SchoolCalendarDate(TimetableClock.now), endDate: nil) }
						}
						Section("Users") { ForEach(filteredUsers) { user in VStack(alignment: .leading) {
							Text(user.displayName); if let email = user.email {
								Text(email).font(.footnote).foregroundStyle(.secondary)
							}
						} } }
					}.searchable(text: $searchText, prompt: "Search users")
				} else {
					ContentUnavailableView("Administration Unavailable", systemImage: "lock", description: Text("This account is not an administrator."))
				}
			}
			.appNavigationTitle("Administration", style: .main)
			.task { await load() }
			.sheet(item: $editor) { entry in AdministrationCalendarEditor(entry: entry) { request, existingID in try await save(request, existingID: existingID) } delete: { id in try await delete(id) } }
		}
	}

	private var filteredUsers: [AdministrationUserResponse] {
		searchText.isEmpty ? users : users.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) }
	}

	private func load() async {
		do {
			let dashboard = try await service.dashboard()
			isAdmin = dashboard.isAdmin
			guard isAdmin else { return }
			async let loadedUsers = service.users()
			async let loadedEntries = service.calendar()
			users = try await loadedUsers
			entries = try await loadedEntries
		} catch { isAdmin = false }
	}

	private func save(_ request: AdministrationCalendarEntryRequest, existingID: UUID?) async throws {
		entries = try await service.save(request, id: existingID)
		try await SchoolCalendarSyncService.shared.downloadCalendar()
	}

	private func delete(_ id: UUID) async throws {
		entries = try await service.delete(id: id)
		try await SchoolCalendarSyncService.shared.downloadCalendar()
	}
}

private struct AdministrationGlobalEventsView: View {
	@Default(.calendarEvents) private var events
	@State private var service = CalendarEventsSyncService.shared
	@State private var title = ""
	@State private var date = TimetableClock.now
	@State private var showCreate = false
	var body: some View {
		List {
			ForEach(events.globalEvents) { event in
				LabeledContent(event.title) { Text(event.date.displayLabel).foregroundStyle(.secondary) }
			}
			Button("Add Global Event", systemImage: "plus") { showCreate = true }
		}
		.appNavigationTitle("Global Events")
		.sheet(isPresented: $showCreate) {
			NavigationStack { Form { TextField("Title", text: $title); DatePicker("Date", selection: $date, displayedComponents: .date) }.appNavigationTitle("Global Event").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showCreate = false } }; ToolbarItem(placement: .confirmationAction) { Button("Add") { Task { try? await service.createEvent(CreateCalendarEventRequest(title: title, notes: nil, symbol: "calendar", date: SchoolCalendarDate(date)), globally: true); showCreate = false } }.disabled(title.isEmpty) } } }
		}
	}
}

private struct AdministrationCalendarEditor: View {
	let entry: AdministrationCalendarEntry; let save: (AdministrationCalendarEntryRequest, UUID?) async throws -> Void; let delete: (UUID) async throws -> Void
	@Environment(\.dismiss) private var dismiss; @State private var label: String; @State private var start: Date; @State private var end: Date
	init(entry: AdministrationCalendarEntry, save: @escaping (AdministrationCalendarEntryRequest, UUID?) async throws -> Void, delete: @escaping (UUID) async throws -> Void) {
		self.entry = entry; self.save = save; self.delete = delete; _label = State(initialValue: entry.label); _start = State(initialValue: entry.startDate.startOfDay() ?? .now); _end = State(initialValue: entry.endDate?.startOfDay() ?? entry.startDate.startOfDay() ?? .now)
	}

	var body: some View {
		NavigationStack { Form {
			TextField("Name", text: $label); DatePicker("Start", selection: $start, displayedComponents: .date); if entry.kind == "term" {
				DatePicker("End", selection: $end, displayedComponents: .date)
			}
		}.appNavigationTitle(entry.kind == "term" ? "Term Date" : "No-School Day").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { Task { try? await save(AdministrationCalendarEntryRequest(kind: entry.kind, label: label, startDate: SchoolCalendarDate(start), endDate: entry.kind == "term" ? SchoolCalendarDate(end) : nil), entry.label.isEmpty ? nil : entry.id); dismiss() } } } }.safeAreaBar(edge: .bottom) {
			if !entry.label.isEmpty {
				Button("Delete", role: .destructive) { Task { try? await delete(entry.id); dismiss() } }
			}
		} }
	}
}
