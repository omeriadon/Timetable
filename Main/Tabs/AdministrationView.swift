import Defaults
import SwiftUI

#if os(iOS)
	import SFSymbolsPicker
#endif

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false

	var body: some View {
		NavigationStack {
			Group {
				if isAdmin {
					List {
						Section {
							NavigationLink {
								AdministrationSchoolEventsView()
							} label: {
								Label("School Events", systemImage: "calendar")
							}

							NavigationLink {
								AdministrationCalendarView()
							} label: {
								Label("School Calendar", systemImage: "calendar.badge.clock")
							}

							NavigationLink {
								AdministrationUsersView()
							} label: {
								Label("Users", systemImage: "person.2")
							}

							NavigationLink {
								AdministrationBroadcastNotificationView()
							} label: {
								Label("Broadcast Notification", systemImage: "megaphone")
							}
						}
					}
				} else {
					ContentUnavailableView(
						"Administration Unavailable",
						systemImage: "lock",
						description: Text("This account is not an administrator.")
					)
				}
			}
			.appNavigationTitle("Administration", style: .main)
			.task {
				await load()
			}
		}
	}

	private func load() async {
		do {
			let dashboard = try await service.dashboard()
			isAdmin = dashboard.isAdmin
		} catch {
			isAdmin = false
		}
	}
}

private struct AdministrationSchoolEventsView: View {
	@Default(.calendarEvents) private var events
	@State private var service = CalendarEventsSyncService.shared
	@State private var editorTarget: AdministrationSchoolEventEditorTarget?

	var body: some View {
		List {
			ForEach(events.globalEvents) { event in
				Button {
					editorTarget = .edit(event)
				} label: {
					LabeledContent {
						Text(event.date.displayLabel)
							.foregroundStyle(.secondary)
					} label: {
						Label(event.title, systemImage: event.symbol)
					}
				}
				.buttonStyle(.plain)
				.swipeActions {
					Button("Delete", systemImage: "trash", role: .destructive) {
						Task {
							try? await delete(event)
						}
					}
				}
			}

			Button("Add School Event", systemImage: "plus") {
				editorTarget = .create
			}
		}
		.appNavigationTitle("School Events")
		.sheet(item: $editorTarget) { target in
			AdministrationSchoolEventEditor(
				target: target,
				save: save,
				delete: delete
			)
			.presentationDetents([.fraction(0.6)])
		}
	}

	private func save(
		_ request: CreateCalendarEventRequest,
		existingEvent: CalendarEvent?
	) async throws {
		if let existingEvent {
			try await service.updateEvent(id: existingEvent.id, request: request, globally: true)
		} else {
			try await service.createEvent(request, globally: true)
		}
	}

	private func delete(_ event: CalendarEvent) async throws {
		try await service.deleteEvent(id: event.id, globally: true)
	}
}

private enum AdministrationSchoolEventEditorTarget: Identifiable {
	case create
	case edit(CalendarEvent)

	var id: String {
		switch self {
		case .create:
			return "create"
		case let .edit(event):
			return event.id.uuidString
		}
	}

	var event: CalendarEvent? {
		if case let .edit(event) = self {
			return event
		}

		return nil
	}
}

private struct AdministrationSchoolEventEditor: View {
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
			.appNavigationTitle(target.event == nil ? "School Event" : "Edit School Event")
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

private struct AdministrationEventSymbolPicker: View {
	@Binding var symbol: String

	#if os(iOS)
		@Environment(\.dismiss) private var dismiss
	#endif

	var body: some View {
		#if os(iOS)
			SymbolsPicker(
				selection: $symbol,
				title: "",
				searchLabel: "Search symbols...",
				autoDismiss: true
			)
		#else
			Form {
				TextField("SF Symbol Name", text: $symbol)
				Label("Preview", systemImage: symbol)
			}
			.padding()
		#endif
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
						Label(
							entry.kind == "term" ? "Term" : "No School",
							systemImage: entry.kind == "term" ? "calendar" : "xmark.circle"
						)
							.foregroundStyle(.secondary)
					}
				}
				.buttonStyle(.plain)
				.swipeActions {
					Button("Delete", systemImage: "trash", role: .destructive) {
						delete(entry.id)
					}
				}
			}

			Button("Add Term Date", systemImage: "plus") {
				editor = newEntry(kind: "term")
			}

			Button("Add No-School Day", systemImage: "plus") {
				editor = newEntry(kind: "noSchool")
			}
		}
		.appNavigationTitle("School Calendar")
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
		entries = (try? await service.calendar()) ?? []
	}

	private func save(
		_ request: AdministrationCalendarEntryRequest,
		existingID: UUID?
	) async throws {
		entries = try await service.save(request, id: existingID)
		try await SchoolCalendarSyncService.shared.downloadCalendar()
	}

	private func delete(_ id: UUID) {
		Task {
			try? await deleteFromEditor(id)
		}
	}

	private func deleteFromEditor(_ id: UUID) async throws {
		entries = try await service.delete(id: id)
		try await SchoolCalendarSyncService.shared.downloadCalendar()
	}

	private func newEntry(kind: String) -> AdministrationCalendarEntry {
		AdministrationCalendarEntry(
			id: UUID(),
			kind: kind,
			label: "",
			startDate: SchoolCalendarDate(TimetableClock.now),
			endDate: kind == "term" ? SchoolCalendarDate(TimetableClock.now) : nil
		)
	}
}

private struct AdministrationUsersView: View {
	@State private var service = AdministrationService.shared
	@State private var users: [AdministrationUserResponse] = []
	@State private var searchText = ""
	@State private var editor: AdministrationUserResponse?

	var body: some View {
		List(filteredUsers) { user in
			Button {
				editor = user
			} label: {
				Label {
					VStack(alignment: .leading) {
						Text(user.displayName)

						if let email = user.email {
							Text(email)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
				} icon: {
					Image(systemName: "person")
				}
			}
		}
		.searchable(text: $searchText, prompt: "Search users")
		.appNavigationTitle("Users")
		.task {
			users = (try? await service.users()) ?? []
		}
		.sheet(item: $editor) { user in
			AdministrationUserEditor(user: user) { updatedUser in
				update(updatedUser)
			}
		}
	}

	private var filteredUsers: [AdministrationUserResponse] {
		guard !searchText.isEmpty else {
			return users
		}

		return users.filter {
			$0.displayName.localizedCaseInsensitiveContains(searchText)
				|| ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
		}
	}

	private func update(_ user: AdministrationUserResponse) {
		guard let index = users.firstIndex(where: { $0.id == user.id }) else {
			return
		}

		users[index] = user
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

	init(
		user: AdministrationUserResponse,
		didSave: @escaping (AdministrationUserResponse) -> Void
	) {
		self.user = user
		self.didSave = didSave
		_displayName = State(initialValue: user.displayName)
		_email = State(initialValue: user.email ?? "")
	}

	var body: some View {
		NavigationStack {
			Form {
				TextField("Name", text: $displayName)
				TextField("Email", text: $email)
					.textInputAutocapitalization(.never)
					.keyboardType(.emailAddress)

				Section {
					SecureField("New Password", text: $password)
				} footer: {
					Text("Leave blank to keep the current password.")
				}
			}
			.appNavigationTitle("User")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						save()
					}
					.disabled(
						displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
							|| email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
					)
					.buttonStyle(.glassProminent)
				}
			}
		}
		.presentationDetents([.fraction(0.6)])
	}

	private func save() {
		Task {
			let request = AdministrationUserUpdateRequest(
				displayName: displayName,
				email: email,
				password: password.isEmpty ? nil : password
			)

			guard let updatedUser = try? await service.updateUser(id: user.id, request: request) else {
				return
			}

			didSave(updatedUser)
			dismiss()
		}
	}
}

private struct AdministrationBroadcastNotificationView: View {
	@State private var service = AdministrationService.shared
	@State private var title = ""
	@State private var subtitle = ""
	@State private var body = ""

	var body: some View {
		Form {
			TextField("Title", text: $title)
			TextField("Subtitle", text: $subtitle)
			TextField("Message", text: $body, axis: .vertical)
				.lineLimit(4 ... 8)
		}
		.appNavigationTitle("Broadcast Notification")
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Send", systemImage: "paperplane.fill", role: .confirm) {
					send()
				}
				.disabled(
					title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
						|| subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
						|| body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
				)
				.buttonStyle(.glassProminent)
			}
		}
	}

	private func send() {
		let request = BroadcastNotificationRequest(
			title: title,
			subtitle: subtitle,
			body: body
		)

		Task {
			try? await service.broadcastNotification(request)
		}
	}
}

private struct AdministrationCalendarEditor: View {
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
