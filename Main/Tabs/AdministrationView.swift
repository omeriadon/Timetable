import Defaults
import SwiftUI

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false

	var body: some View {
		NavigationStack {
			Group {
				if isAdmin {
					List {
						Section {
							NavigationLink { AdministrationSchoolEventsView() } label: {
								Label("School Events", systemImage: "calendar")
							}
							NavigationLink { AdministrationCalendarView() } label: {
								Label("School Calendar", systemImage: "calendar.badge.clock")
							}
							NavigationLink { AdministrationUsersView() } label: {
								Label("Users", systemImage: "person.2")
							}
						}
					}
				} else {
					ContentUnavailableView("Administration Unavailable", systemImage: "lock", description: Text("This account is not an administrator."))
				}
			}
			.appNavigationTitle("Administration", style: .main)
			.task { await load() }
		}
	}

	private func load() async {
		do {
			let dashboard = try await service.dashboard()
			isAdmin = dashboard.isAdmin
		} catch { isAdmin = false }
	}
}

private struct AdministrationSchoolEventsView: View {
	@Default(.calendarEvents) private var events
	@State private var service = CalendarEventsSyncService.shared
	@State private var title = ""
	@State private var date = TimetableClock.now
	@State private var showCreate = false
	var body: some View {
		List {
			ForEach(events.globalEvents) { event in
				LabeledContent(event.title) { Text(event.date.displayLabel).foregroundStyle(.secondary) }
					.swipeActions {
						Button("Delete", systemImage: "trash", role: .destructive) {
							Task { try? await service.deleteEvent(id: event.id, globally: true) }
						}
					}
			}
			Button("Add School Event", systemImage: "plus") { showCreate = true }
		}
		.appNavigationTitle("School Events")
		.sheet(isPresented: $showCreate) {
			NavigationStack {
				Form {
					TextField("Title", text: $title); DatePicker("Date", selection: $date, displayedComponents: .date)
				}
				.appNavigationTitle("School Event")
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button(role: .cancel) {
							showCreate = false
						}
					}

					ToolbarItem(placement: .confirmationAction) {
						Button("Add", systemImage: "plus", role: .confirm){
							Task {
								try? await service.createEvent(
									CreateCalendarEventRequest(
										title: title,
										notes: nil,
										symbol: "calendar",
										date: SchoolCalendarDate(
											date
										)
									),
									globally: true
								); showCreate = false
							}
						}.disabled(
							title.isEmpty
						)
						.buttonStyle(.glassProminent)
					}
				}
			}
		}
	}
}

private struct AdministrationCalendarView: View {
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
						Text(entry.kind == "term" ? "Term" : "No School").foregroundStyle(.secondary)
					}
				}
				.buttonStyle(.plain)
				.swipeActions {
					Button("Delete", systemImage: "trash", role: .destructive) {
						Task { await delete(entry.id) }
					}
				}
			}
			Button("Add Term Date", systemImage: "plus") { editor = newEntry(kind: "term") }
			Button("Add No-School Day", systemImage: "plus") { editor = newEntry(kind: "noSchool") }
		}
		.appNavigationTitle("School Calendar")
		.task { await load() }
		.sheet(item: $editor) { entry in
			AdministrationCalendarEditor(entry: entry) { request, existingID in
				entries = try await service.save(request, id: existingID)
				try await SchoolCalendarSyncService.shared.downloadCalendar()
			} delete: { id in
				entries = try await service.delete(id: id)
				try await SchoolCalendarSyncService.shared.downloadCalendar()
			}
		}
	}

	private func load() async { entries = (try? await service.calendar()) ?? [] }

	private func delete(_ id: UUID) async {
		guard let updatedEntries = try? await service.delete(id: id) else { return }
		entries = updatedEntries
		try? await SchoolCalendarSyncService.shared.downloadCalendar()
	}

	private func newEntry(kind: String) -> AdministrationCalendarEntry {
		AdministrationCalendarEntry(id: UUID(), kind: kind, label: "", startDate: SchoolCalendarDate(TimetableClock.now), endDate: kind == "term" ? SchoolCalendarDate(TimetableClock.now) : nil)
	}
}

private struct AdministrationUsersView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""

	var body: some View {
		List(filteredUsers) { user in
			NavigationLink {
				AdministrationUserEditor(user: user) { updatedUser in
					guard let index = users.firstIndex(where: { $0.id == updatedUser.id }) else { return }
					users[index] = updatedUser
				}
			} label: {
				VStack(alignment: .leading) {
					Text(user.displayName)
					if let email = user.email { Text(email).font(.footnote).foregroundStyle(.secondary) }
				}
			}
		}
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users")
		.task { users = (try? await service.users()) ?? [] }
	}

	private var filteredUsers: [AdministrationUserResponse] {
		searchText.isEmpty ? users : users.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) }
	}
}

private struct AdministrationUserEditor: View {
	let user: AdministrationUserResponse
	let didSave: (AdministrationUserResponse) -> Void
	@Environment(\.dismiss) private var dismiss
	@State private var service = AdministrationService.shared
	@State private var displayName: String
	@State private var email: String
	@State private var password = ""

	init(user: AdministrationUserResponse, didSave: @escaping (AdministrationUserResponse) -> Void) {
		self.user = user
		self.didSave = didSave
		_displayName = State(initialValue: user.displayName)
		_email = State(initialValue: user.email ?? "")
	}

	var body: some View {
		Form {
			TextField("Name", text: $displayName)
			TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
			Section {
				SecureField("New Password", text: $password)
			} footer: {
				Text("Leave blank to keep the current password.")
			}
		}
		.appNavigationTitle("User")
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Save") {
					Task {
						guard let updatedUser = try? await service.updateUser(id: user.id, request: AdministrationUserUpdateRequest(displayName: displayName, email: email, password: password.isEmpty ? nil : password)) else { return }
						didSave(updatedUser)
						dismiss()
					}
				}
				.disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
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
