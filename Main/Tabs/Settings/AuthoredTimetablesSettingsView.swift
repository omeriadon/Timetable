//
//   AuthoredTimetablesSettingsView.swift
//   Main
//
//   Created by Adon Omeri on 29/6/2026.
//

import SwiftUI

struct AuthoredTimetablesSettingsView: View {
	@State private var service = AuthoredTimetableService.shared
	@Environment(\.statusBadgeManager) private var badges
	@State private var showCreate = false
	@State private var networkManager = NetworkManager.shared

	@Namespace var ns

	var body: some View {
		Text("Authored Timetables")
			.bold()
			.padding(.leading, 4)
			.font(.largeTitle)
			.lineLimit(3)
			.frame(maxWidth: .infinity, alignment: .leading)

		List(service.timetables) { timetable in
			NavigationLink {
				AuthoredTimetableEditorView(timetable: timetable)
			} label: {
				VStack(alignment: .leading) { Text(timetable.title)
					Text(timetable.isSearchable ? "Searchable" : "Hidden")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Create Timetable", systemImage: "plus") { showCreate = true }
					.buttonStyle(.glassProminent)
			}
			.matchedTransitionSource(id: "1", in: ns)
		}
		.sheet(isPresented: $showCreate) {
			AuthoredTimetableCreateView()
				.presentationDetents([.medium])
				.navigationTransition(
					.zoom(sourceID: "1", in: ns)
				)
		}
		.overlay {
			if !networkManager.isOnline {
				ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text("Authored timetables are unavailable until a connection is restored."))
			} else if service.timetables.isEmpty {
				ContentUnavailableView("No Authored Timetables", systemImage: "person.2.crop.square.stack")
					.fontWeight(.regular)
					.foregroundStyle(.secondary)
			}
		}
		.refreshable { await refresh() }
		.task {
			if networkManager.isOnline {
				await refresh()
			}
		}
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
			Text("New Authored Timetable")
				.bold()
				.padding(.leading, 4)
				.font(.largeTitle)
				.lineLimit(3)
				.frame(maxWidth: .infinity, alignment: .leading)

			Form {
				TextField("Title", text: $title)
				Toggle("Searchable", isOn: $isSearchable)
				Button("Edit Subjects", systemImage: "pencil") { showSubjectEditor = true }
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", systemImage: "xmark", role: .cancel) {
						dismiss()
					}
					.disabled(isSaving)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create", systemImage: "checkmark", role: .confirm) {
						Task {
							await create()
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.sheet(isPresented: $showSubjectEditor) {
				SubjectEditorSheet(subjects: $subjects, initialRequest: nil)
					.presentationDetents([.large])
					.presentationDragIndicator(.hidden)
					.interactiveDismissDisabled()
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
		Form {
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
		.appNavigationTitle(title)
		.toolbar {
			ToolbarItem(
				placement: .confirmationAction
			) { Button("Save") { Task { await save() } } }
		}
		.sheet(
			isPresented: $showEditor
		) {
			SubjectEditorSheet(subjects: $subjects, initialRequest: nil)
				.presentationDetents([.large])
				.presentationDragIndicator(.hidden)
				.interactiveDismissDisabled()
		}
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
