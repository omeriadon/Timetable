import SwiftUI

struct AdministrationEventTagSectionEditor: View {
	let section: AdministrationEventTagSection
	let save: (AdministrationEventTagSectionUpdateRequest, UUID) async throws -> Void
	let saveTag: (AdministrationEventTagRequest, UUID?) async throws -> Void

	let close: () -> Void = {}
	@State private var displayName: String
	@State private var sortOrder: Int
	@State private var isArchived: Bool
	@State private var isSaving = false
	@State private var showsArchiveConfirmation = false

	init(
		section: AdministrationEventTagSection,
		save: @escaping (AdministrationEventTagSectionUpdateRequest, UUID) async throws -> Void,
		saveTag: @escaping (AdministrationEventTagRequest, UUID?) async throws -> Void
	) {
		self.section = section
		self.save = save
		self.saveTag = saveTag
		_displayName = State(initialValue: section.displayName)
		_sortOrder = State(initialValue: section.sortOrder)
		_isArchived = State(initialValue: section.isArchived)
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Section") {
					TextField("Display Name", text: $displayName)
					LabeledContent("Category", value: section.category.displayName)
					Stepper("Sort Order: \(sortOrder)", value: $sortOrder)
					Toggle("Archive Section", isOn: $isArchived)

					NavigationLink {
						AdministrationEventTagSectionTagsView(
							section: section,
							save: saveTag
						)
					} label: {
						Label("Tags", systemImage: "tag")
					}
				}
			}
			.scrollEdgeEffect()
			.appGroupedFormStyle()
			.appNavigationTitle("Edit Section", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						close()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						if !section.isArchived, isArchived {
							showsArchiveConfirmation = true
						} else {
							Task {
								await saveSection()
							}
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
			}
			.confirmationDialog(
				"Archive Section?",
				isPresented: $showsArchiveConfirmation,
				titleVisibility: .visible
			) {
				Button("Archive Section", systemImage: "archivebox", role: .destructive) {
					Task {
						await saveSection()
					}
				}
			} message: {
				Text("Archived sections and their tags are removed from active selection.")
			}
		}
		.presentationDetents([.fraction(0.6)])
	}

	private func saveSection() async {
		isSaving = true
		defer {
			isSaving = false
		}

		do {
			try await save(
				AdministrationEventTagSectionUpdateRequest(
					displayName: displayName,
					sortOrder: sortOrder,
					isArchived: isArchived
				),
				section.id
			)
			close()
		} catch {
			return
		}
	}
}
