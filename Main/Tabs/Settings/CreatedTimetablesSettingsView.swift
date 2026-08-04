//
//   CreatedTimetablesSettingsView.swift
//   Main
//
//   Created by Adon Omeri on 29/6/2026.
//

import SwiftUI

struct CreatedTimetablesSettingsView: View {
	let closeWideDestination: (() -> Void)?
	@State private var service = CreatedTimetableService.shared
	@Environment(\.statusBadgeManager) private var badges
	@State private var showCreate = false
	@State private var networkManager = NetworkManager.shared
	@Environment(\.appPresentation) private var presentation

	var body: some View {
		List(service.timetables) { timetable in
			NavigationLink {
				CreatedTimetableEditorView(
					timetable: timetable,
					close: closeWideEditor
				)
			} label: {
				VStack(alignment: .leading) {
					Text(timetable.title)
					Text("Private")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
		.appNavigationTitle("Created Timetables", accent: true)
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				if presentation == .iOS {
					Button("Create Timetable", systemImage: "plus") {
						showCreate = true
					}
					.buttonStyle(.glassProminent)
				} else {
					NavigationLink {
						CreatedTimetableCreateView(
							close: closeWideEditor,
							embedsInNavigation: false,
							showsCloseButton: false
						)
					} label: {
						Label("Create Timetable", systemImage: "plus")
					}
					.buttonStyle(.glassProminent)
				}
			}
		}
		.sheet(isPresented: $showCreate) {
			CreatedTimetableCreateView(close: { showCreate = false })
				.presentationDetents([.medium])
		}
		.overlay {
			if !networkManager.isOnline {
				ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text("Created timetables are unavailable until a connection is restored."))
			} else if service.timetables.isEmpty {
				ContentUnavailableView("No Created Timetables", systemImage: "person.2.crop.square.stack")
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

	private func closeWideEditor() {
		closeWideDestination?()
	}

	private func refresh() async {
		do { try await service.refresh() }
		catch let error as NetworkError where error.suppressesStatusBadge {}
		catch { badges.addBadge(id: UUID(), title: "Unable to load created timetables", secondaryText: error.localizedDescription, priority: 4, view: .error) }
	}
}

private struct CreatedTimetableCreateView: View {
	@State private var title = ""
	@State private var subjects: [Subject] = []
	@State private var showSubjectEditor = false
	@State private var isSaving = false
	let close: () -> Void
	let embedsInNavigation: Bool
	let showsCloseButton: Bool
	@Environment(\.statusBadgeManager) private var badges

	init(
		close: @escaping () -> Void,
		embedsInNavigation: Bool = true,
		showsCloseButton: Bool = true
	) {
		self.close = close
		self.embedsInNavigation = embedsInNavigation
		self.showsCloseButton = showsCloseButton
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
			TextField("Title", text: $title)
			Button("Edit Subjects", systemImage: "pencil") {
				showSubjectEditor = true
			}
		}
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
		.appNavigationTitle("New Created Timetable", accent: true)
		.toolbar {
			if showsCloseButton {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						close()
					}
					.disabled(isSaving)
				}
			}

			ToolbarItem(placement: .confirmationAction) {
				Button("Create", systemImage: "checkmark", role: .confirm) {
					Task {
						await create()
					}
				}
				.buttonStyle(.glassProminent)
				.labelStyle(.iconOnly)
				.disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
		}
		.sheet(isPresented: $showSubjectEditor) {
			SubjectEditorSheet(subjects: $subjects, initialRequest: nil)
				.presentationDetents([.large])
				.presentationDragIndicator(.hidden)
		}
	}

	private func create() async {
		isSaving = true
		defer { isSaving = false }
		do {
			try await CreatedTimetableService.shared.create(title: title, subjects: subjects)
			close()
		} catch {
			badges.addBadge(id: UUID(), title: "Unable to create timetable", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}

private struct CreatedTimetableEditorView: View {
	let timetable: TimetableDetailResponse
	@State private var title: String
	@State private var subjects: [Subject]
	@State private var showEditor = false
	@State private var confirmDelete = false
	@State private var saveTask: Task<Void, Never>?
	let close: () -> Void
	@Environment(\.statusBadgeManager) private var badges

	init(
		timetable: TimetableDetailResponse,
		close: @escaping () -> Void
	) {
		self.timetable = timetable
		self.close = close
		_title = State(initialValue: timetable.title)
		_subjects = State(initialValue: timetable.subjects)
	}

	var body: some View {
		Form {
			Section("Details") {
				TextField("Title", text: $title)
					.onSubmit { scheduleSave(immediately: true) }
			}
			Section("Timetable") {
				TimetablePreviewGrid(subjects: subjects)

				Button("Edit Subjects", systemImage: "pencil") {
					showEditor = true
				}
			}
			Section {
				Button(role: .destructive) {
					confirmDelete = true
				} label: {
					Label("Delete Timetable", systemImage: "trash")
						.foregroundStyle(.red)
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
				} message: {
					Text(
						"This removes the timetable from the server and revokes installed passes."
					)
				}
			}
		}
		.appNavigationTitle(title, accent: true)
		.sheet(
			isPresented: $showEditor
		) {
			SubjectEditorSheet(subjects: $subjects, initialRequest: nil)
				.presentationDetents([.large])
				.presentationDragIndicator(.hidden)
		}
		.onChange(of: subjects) {
			scheduleSave()
		}
		.onChange(of: title) {
			scheduleSave()
		}
		.onDisappear {
			saveTask?.cancel()
		}
	}

	private func scheduleSave(immediately: Bool = false) {
		saveTask?.cancel()
		let title = title
		let subjects = subjects

		saveTask = Task {
			if !immediately {
				do {
					try await Task.sleep(for: .milliseconds(300))
				} catch {
					return
				}
			}

			guard !Task.isCancelled else {
				return
			}

			do {
				try await CreatedTimetableService.shared.update(id: timetable.id, title: title, subjects: subjects)
			} catch {
				guard !Task.isCancelled else {
					return
				}

				badges.addBadge(
					id: UUID(),
					title: "Unable to save timetable",
					secondaryText: error.localizedDescription,
					priority: 4,
					view: .error
				)
			}
		}
	}

	private func delete() async {
		do {
			try await CreatedTimetableService.shared.delete(id: timetable.id)
			badges.addBadge(id: UUID(), title: "Timetable deleted", priority: 3, view: .success)
			close()
		} catch {
			badges.addBadge(id: UUID(), title: "Unable to delete timetable", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}
