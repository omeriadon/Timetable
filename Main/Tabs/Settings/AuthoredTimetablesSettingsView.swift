import SwiftUI

struct AuthoredTimetablesSettingsView: View {
	@State private var service = AuthoredTimetableService.shared
	@Environment(\.statusBadgeManager) private var badges
	@State private var showCreate = false

	var body: some View {
		ScrollView {
			AppNavigationHeader()

			LazyVStack(alignment: .leading, spacing: 12) {
				ForEach(service.timetables) { timetable in
					NavigationLink { AuthoredTimetableEditorView(timetable: timetable) } label: {
						VStack(alignment: .leading) { Text(timetable.title)
							Text(timetable.isSearchable ? "Searchable" : "Hidden")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
				}
			}
			.padding()
		}
		.appNavigationTitle("Authored Timetables")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Create Timetable", systemImage: "plus") { showCreate = true }
			}
		}
		.sheet(isPresented: $showCreate) { AuthoredTimetableCreateView() }
		.overlay { if service.timetables.isEmpty { ContentUnavailableView("No Authored Timetables", systemImage: "person.2.crop.square.stack") } }
		.refreshable { await refresh() }
		.task { await refresh() }
	}

	private func refresh() async {
		do { try await service.refresh() }
		catch let error as NetworkError where error.suppressesStatusBadge {}
		catch { badges.addBadge(id: UUID(), title: "Unable to load authored timetables", secondaryText: error.localizedDescription, priority: 4, view: .error) }
	}
}

private struct AuthoredTimetableCreateView: View {
	@State private var title = ""
	@State private var subjects: [Subject] = []
	@State private var isSearchable = true
	@State private var showSubjectEditor = false
	@State private var isSaving = false
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		NavigationStack {
			ScrollView {
				AppNavigationHeader()

				LazyVStack(alignment: .leading, spacing: 20) {
					TextField("Title", text: $title)
					Toggle("Searchable", isOn: $isSearchable)
					Button("Edit Subjects", systemImage: "pencil") { showSubjectEditor = true }
				}
				.padding()
			}
			.appNavigationTitle("New Authored Timetable")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(isSaving) }
				ToolbarItem(placement: .confirmationAction) { Button("Create") { Task { await create() } }.disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
			}
			.sheet(isPresented: $showSubjectEditor) {
				SubjectEditorSheet(subjects: $subjects, initialRequest: nil).interactiveDismissDisabled()
			}
		}
	}

	private func create() async {
		isSaving = true
		defer { isSaving = false }
		do {
			try await AuthoredTimetableService.shared.create(title: title, subjects: subjects, isSearchable: isSearchable)
			badges.addBadge(id: UUID(), title: "Authored timetable created", priority: 3, view: .success)
			dismiss()
		} catch {
			badges.addBadge(id: UUID(), title: "Unable to create timetable", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}

private struct AuthoredTimetableEditorView: View {
	let timetable: TimetableDetailResponse
	@State private var title: String
	@State private var subjects: [Subject]
	@State private var isSearchable: Bool
	@State private var showEditor = false
	@State private var confirmDelete = false
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges

	init(timetable: TimetableDetailResponse) {
		self.timetable = timetable
		_title = State(initialValue: timetable.title)
		_subjects = State(initialValue: timetable.subjects)
		_isSearchable = State(initialValue: timetable.isSearchable)
	}

	var body: some View {
		ScrollView {
			AppNavigationHeader()

			LazyVStack(alignment: .leading, spacing: 20) {
				Section("Details") {
					TextField("Title", text: $title)
					Toggle("Searchable", isOn: $isSearchable)
				}
				Section("Timetable") {
					TimetablePreviewGrid(subjects: subjects)

					Button("Edit Subjects", systemImage: "pencil") {
						showEditor = true
					}
				}
				Section {
					Button(
						"Delete Timetable",
						systemImage: "trash",
						role: .destructive
					) {
						confirmDelete = true
					}
				}
			}
			.padding()
		}
		.appNavigationTitle(title)
		.toolbar {
			ToolbarItem(
				placement: .confirmationAction
			) { Button("Save") { Task { await save() } } }
		}
		.sheet(
			isPresented: $showEditor
		) { SubjectEditorSheet(subjects: $subjects, initialRequest: nil).interactiveDismissDisabled() }
		.confirmationDialog(
			"Delete this timetable?",
			isPresented: $confirmDelete
		) {
			Button("Delete Timetable", role: .destructive) {
				Task {
					await delete()
				}
			}
			Button(
				"Cancel",
				role: .cancel
			) {}
		} message: {
			Text(
				"This removes the timetable from the server and revokes installed passes."
			)
		}
	}

	private func save() async {
		do {
			try await AuthoredTimetableService.shared.update(id: timetable.id, title: title, subjects: subjects, isSearchable: isSearchable)
			badges.addBadge(id: UUID(), title: "Authored timetable saved", priority: 3, view: .success)
		} catch {
			badges.addBadge(
				id: UUID(),
				title: "Unable to save timetable",
				secondaryText: error.localizedDescription,
				priority: 4,
				view: .error
			)
		}
	}

	private func delete() async {
		do {
			try await AuthoredTimetableService.shared.delete(id: timetable.id)
			badges.addBadge(id: UUID(), title: "Timetable deleted", priority: 3, view: .success)
			dismiss()
		} catch {
			badges.addBadge(id: UUID(), title: "Unable to delete timetable", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}
