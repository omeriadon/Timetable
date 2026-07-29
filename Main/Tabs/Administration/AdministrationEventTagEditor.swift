import SwiftUI

struct AdministrationEventTagEditor: View {
	let tag: AdministrationEventTag?
	let section: AdministrationEventTagSection
	let sections: [AdministrationEventTagSection]
	let save: (AdministrationEventTagRequest, UUID?) async throws -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var sectionID: UUID
	@State private var slug: String
	@State private var displayName: String
	@State private var symbol: String
	@State private var colorHex: String
	@State private var sortOrder: Int
	@State private var isArchived: Bool
	@State private var associatedNames: String
	@State private var isSaving = false

	init(
		tag: AdministrationEventTag?,
		section: AdministrationEventTagSection,
		sections: [AdministrationEventTagSection],
		save: @escaping (AdministrationEventTagRequest, UUID?) async throws -> Void
	) {
		self.tag = tag
		self.section = section
		self.sections = sections
		self.save = save
		_sectionID = State(initialValue: tag?.sectionID ?? section.id)
		_slug = State(initialValue: tag?.slug ?? "")
		_displayName = State(initialValue: tag?.displayName ?? "")
		_symbol = State(initialValue: tag?.symbol ?? "")
		_colorHex = State(initialValue: tag?.colorHex ?? "")
		_sortOrder = State(initialValue: tag?.sortOrder ?? section.tags.count)
		_isArchived = State(initialValue: tag?.isArchived ?? false)
		_associatedNames = State(initialValue: tag?.associatedNames.joined(separator: "\n") ?? "")
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Tag") {
					TextField("Display Name", text: $displayName)
					TextField("Slug", text: $slug)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					TextField("Symbol", text: $symbol)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					TextField("Colour Hex", text: $colorHex)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					Stepper("Sort Order: \(sortOrder)", value: $sortOrder)
					Toggle("Archive Tag", isOn: $isArchived)
				}

				Section("Section") {
					Picker("Section", selection: $sectionID) {
						ForEach(sections) { section in
							Text(section.displayName)
								.tag(section.id)
						}
					}
				}

				Section("Associated Names") {
					TextEditor(text: $associatedNames)
						.frame(minHeight: 110)
				} footer: {
					Text("One alternate name per line. The display name is always included.")
				}
			}
			.scrollEdgeEffect()
			.appNavigationTitle(tag == nil ? "Add Tag" : "Edit Tag", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						Task {
							await saveTag()
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
			}
		}
		.presentationDetents([.fraction(0.7)])
	}

	private func saveTag() async {
		isSaving = true
		defer {
			isSaving = false
		}

		let request = AdministrationEventTagRequest(
			sectionID: sectionID,
			slug: slug,
			displayName: displayName,
			symbol: symbol.nilIfBlank,
			colorHex: colorHex.nilIfBlank,
			sortOrder: sortOrder,
			isArchived: isArchived,
			associatedNames: associatedNames
				.split(whereSeparator: \.isNewline)
				.map(String.init)
		)

		do {
			try await save(request, tag?.id)
			dismiss()
		} catch {
			return
		}
	}
}

private extension String {
	var nilIfBlank: String? {
		let value = trimmingCharacters(in: .whitespacesAndNewlines)
		return value.isEmpty ? nil : value
	}
}
