import Foundation
import SwiftUI

struct AdministrationEventTagEditor: View {
	let tag: AdministrationEventTag?
	let section: AdministrationEventTagSection
	let save: (AdministrationEventTagRequest, UUID?) async throws -> Void

	@Environment(\.dismiss) private var dismiss
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
	@State private var showsSymbolPicker = false

	private var isCanonicalYearGroup: Bool {
		tag?.category == .yearGroup
	}

	init(
		tag: AdministrationEventTag?,
		section: AdministrationEventTagSection,
		save: @escaping (AdministrationEventTagRequest, UUID?) async throws -> Void
	) {
		self.tag = tag
		self.section = section
		self.save = save
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
			Form {
				Section("Tag") {
					TextField("Display Name", text: $displayName)
					TextField("Slug", text: $slug)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.disabled(isCanonicalYearGroup)
					Button {
						showsSymbolPicker = true
					} label: {
						Label("Symbol", systemImage: symbol)
					}
					ColorPicker("Colour", selection: $colour, supportsOpacity: false)
					Toggle("Archive Tag", isOn: $isArchived)
						.disabled(isCanonicalYearGroup)
				}

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
			}
			.appNavigationTitle(tag == nil ? "Add Tag" : "Edit Tag", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
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
		.interactiveDismissDisabled()
		.presentationDetents([.large])
		.sheet(isPresented: $showsSymbolPicker) {
			AdministrationEventSymbolPicker(symbol: $symbol)
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
			dismiss()
		} catch {
			return
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
