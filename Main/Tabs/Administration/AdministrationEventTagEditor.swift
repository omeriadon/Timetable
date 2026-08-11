import Foundation
import SwiftUI

struct AdministrationEventTagEditor: View {
	let tag: AdministrationEventTag?
	let section: AdministrationEventTagSection
	let save: (AdministrationEventTagRequest, UUID?) async throws -> Void
	let delete: (UUID) async throws -> Void

	let close: () -> Void
	@State private var sectionID: UUID
	@State private var slug: String
	@State private var displayName: String
	@State private var symbol: String
	@State private var colour: Color
	private let sortOrder: Int
	@State private var isArchived: Bool
	@State private var associatedNames: String
	@State private var isSaving = false
	@State private var showsArchiveConfirmation = false
	@State private var showsDeleteConfirmation = false
	@State private var showsSymbolPicker = false
	@Environment(\.appPresentation) private var presentation
	@Environment(\.statusBadgeManager) private var statusBadges

	private var isCanonicalYearGroup: Bool {
		tag?.category == .yearGroup
	}

	init(
		tag: AdministrationEventTag?,
		section: AdministrationEventTagSection,
		save: @escaping (AdministrationEventTagRequest, UUID?) async throws -> Void,
		delete: @escaping (UUID) async throws -> Void,
		close: @escaping () -> Void
	) {
		self.tag = tag
		self.section = section
		self.save = save
		self.delete = delete
		self.close = close
		_sectionID = State(initialValue: section.id)
		_slug = State(initialValue: tag?.slug ?? "")
		_displayName = State(initialValue: tag?.displayName ?? "")
		_symbol = State(initialValue: tag?.symbol ?? "")
		_colour = State(initialValue: RGBAColor(hexString: tag?.colorHex ?? "#6AA7FF").swiftUIColor)
		sortOrder = tag?.sortOrder ?? section.tags.count
		_isArchived = State(initialValue: tag?.isArchived ?? false)
		_associatedNames = State(initialValue: tag?.associatedNames.joined(separator: "\n") ?? "")
	}

	var body: some View {
		NavigationStack {
			List {
				Section("Tag") {
					TextField("Display Name", text: $displayName)
					TextField("Slug", text: $slug)

						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.disabled(isCanonicalYearGroup)
					if presentation == .iOS {
						Button {
							showsSymbolPicker = true
						} label: {
							Label("Symbol", systemImage: symbol)
						}
					} else {
						NavigationLink {
							AdministrationEventSymbolPicker(symbol: $symbol)
						} label: {
							Label("Symbol", systemImage: symbol)
						}
					}
					ColorPicker("Colour", selection: $colour, supportsOpacity: false)
					Toggle("Archive Tag", isOn: $isArchived)
						.disabled(isCanonicalYearGroup)
				}
				.glurListRowBackground()

				Section {
					TextEditor(text: $associatedNames)
						.frame(minHeight: 110)
						.disabled(isCanonicalYearGroup)
				} header: {
					Text("Associated Names")
				} footer: {
					Text(
						isCanonicalYearGroup
							? "Canonical year-group names cannot be changed."
							: "One alternate name per line. The display name is always included."
					)
				}
				.glurListRowBackground()

				if let tag, !isCanonicalYearGroup {
					Section {
						Button("Delete Tag", systemImage: "trash", role: .destructive) {
							showsDeleteConfirmation = true
						}
						.disabled(isSaving)
					}
					.glurListRowBackground()
					.confirmationDialog(
						"Delete \(tag.displayName)?",
						isPresented: $showsDeleteConfirmation,
						titleVisibility: .visible
					) {
						Button("Delete Tag", systemImage: "trash", role: .destructive) {
							Task {
								await deleteTag(tag.id)
							}
						}
					} message: {
						Text("This permanently removes the tag from every event and account subscription.")
					}
				}
			}
			.appPaperBackground()
			.appNavigationTitle(tag == nil ? "Add Tag" : "Edit Tag", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						close()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						if tag?.isArchived == false, isArchived {
							showsArchiveConfirmation = true
						} else {
							Task {
								await saveTag()
							}
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
			}
			.confirmationDialog(
				"Archive Tag?",
				isPresented: $showsArchiveConfirmation,
				titleVisibility: .visible
			) {
				Button("Archive Tag", systemImage: "archivebox", role: .destructive) {
					Task {
						await saveTag()
					}
				}
			} message: {
				Text("Archived tags are removed from active selection and subscriptions.")
			}
		}
		.presentationDetents([.large])
		.sheet(isPresented: $showsSymbolPicker) {
			AdministrationEventSymbolPicker(symbol: $symbol)
				.appPaperPresentation()
		}
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
			colorHex: colour.toHexString,
			sortOrder: sortOrder,
			isArchived: isArchived,
			associatedNames: associatedNames
				.split(whereSeparator: \.isNewline)
				.map(String.init)
		)

		do {
			try await save(request, tag?.id)
			close()
		} catch {
			statusBadges.present(error: error, title: "Unable to save tag")
		}
	}

	private func deleteTag(_ id: UUID) async {
		isSaving = true
		defer {
			isSaving = false
		}

		do {
			try await delete(id)
			close()
		} catch {
			statusBadges.present(error: error, title: "Unable to delete tag")
		}
	}
}

private extension Color {
	var toHexString: String {
		let rgba = toRGBA()
		return String(
			format: "#%02X%02X%02X",
			Int(rgba.r * 255),
			Int(rgba.g * 255),
			Int(rgba.b * 255)
		)
	}
}

private extension String {
	var nilIfBlank: String? {
		let value = trimmingCharacters(in: .whitespacesAndNewlines)
		return value.isEmpty ? nil : value
	}
}
