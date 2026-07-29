import SwiftUI

struct AdministrationEventTagSectionEditor: View {
	let section: AdministrationEventTagSection?
	let save: (
		AdministrationEventTagSectionCreateRequest?,
		AdministrationEventTagSectionUpdateRequest?,
		UUID?
	) async throws -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var category: AdministrationEventTagCategory
	@State private var displayName: String
	@State private var sortOrder: Int
	@State private var isArchived: Bool
	@State private var isSaving = false

	init(
		section: AdministrationEventTagSection?,
		save: @escaping (
			AdministrationEventTagSectionCreateRequest?,
			AdministrationEventTagSectionUpdateRequest?,
			UUID?
		) async throws -> Void
	) {
		self.section = section
		self.save = save
		_category = State(initialValue: section?.category ?? .subject)
		_displayName = State(initialValue: section?.displayName ?? "")
		_sortOrder = State(initialValue: section?.sortOrder ?? 0)
		_isArchived = State(initialValue: section?.isArchived ?? false)
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Section") {
					TextField("Display Name", text: $displayName)
					Picker("Category", selection: $category) {
						ForEach(AdministrationEventTagCategory.allCases) { category in
							Text(category.displayName)
								.tag(category)
						}
					}
					.disabled(section != nil)
					Stepper("Sort Order: \(sortOrder)", value: $sortOrder)
					Toggle("Archive Section", isOn: $isArchived)
						.disabled(section == nil)
				}
			}
			.scrollEdgeEffect()
			.appNavigationTitle(section == nil ? "Add Section" : "Edit Section", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						Task {
							await saveSection()
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
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
			if let section {
				try await save(
					nil,
					AdministrationEventTagSectionUpdateRequest(
						displayName: displayName,
						sortOrder: sortOrder,
						isArchived: isArchived
					),
					section.id
				)
			} else {
				try await save(
					AdministrationEventTagSectionCreateRequest(
						category: category,
						displayName: displayName,
						sortOrder: sortOrder
					),
					nil,
					nil
				)
			}
			dismiss()
		} catch {
			return
		}
	}
}
