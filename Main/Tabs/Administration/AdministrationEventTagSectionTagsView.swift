import SwiftUI

struct AdministrationEventTagSectionTagsView: View {
	let section: AdministrationEventTagSection
	let save: (AdministrationEventTagRequest, UUID?) async throws -> Void

	@State private var service = AdministrationService.shared
	@State private var tags: [AdministrationEventTag]
	@State private var editor: AdministrationEventTagEditorTarget?
	@State private var isReordering = false

	init(
		section: AdministrationEventTagSection,
		save: @escaping (AdministrationEventTagRequest, UUID?) async throws -> Void
	) {
		self.section = section
		self.save = save
		_tags = State(initialValue: section.tags)
	}

	var body: some View {
		List {
			ForEach(tags) { tag in
				Button {
					editor = .tag(tag, section: section)
				} label: {
					Label {
						VStack(alignment: .leading, spacing: 4) {
							Text(tag.displayName)
							Text(tag.slug)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: tag.symbol ?? "tag")
					}
				}
				.buttonStyle(.plain)
				.opacity(tag.isArchived ? 0.55 : 1)
			}
			.onMove(perform: move)

			if section.category != .yearGroup {
				Button("Add Tag", systemImage: "plus") {
					editor = .newTag(section)
				}
			}
		}

		.environment(\.editMode, .constant(isReordering ? .active : .inactive))
		.appNavigationTitle(section.displayName)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button(
					isReordering ? "Done" : "Reorder",
					systemImage: isReordering ? "checkmark" : "arrow.up.arrow.down"
				) {
					isReordering.toggle()
				}
			}
		}
		.sheet(item: $editor) { target in
			Group {
				switch target {
					case let .tag(tag, section):
						AdministrationEventTagEditor(
							tag: tag,
							section: section,
							save: saveTag,
							close: { editor = nil }
						)
					case let .newTag(section):
						AdministrationEventTagEditor(
							tag: nil,
							section: section,
							save: saveTag,
							close: { editor = nil }
						)
				}
			}
		}
		.task {
			await reloadFromServer()
		}
	}

	private func move(from offsets: IndexSet, to destination: Int) {
		tags.move(fromOffsets: offsets, toOffset: destination)
		Task {
			await reorderTags()
			await reloadFromServer()
		}
	}

	private func reorderTags() async {
		for (index, tag) in tags.enumerated() {
			let request = AdministrationEventTagRequest(
				sectionID: tag.sectionID,
				slug: tag.slug,
				displayName: tag.displayName,
				symbol: tag.symbol,
				colorHex: tag.colorHex,
				sortOrder: index,
				isArchived: tag.isArchived,
				associatedNames: tag.associatedNames
			)
			try? await save(request, tag.id)
		}
	}

	private func saveTag(
		_ request: AdministrationEventTagRequest,
		existingID: UUID?
	) async throws {
		try await save(request, existingID)
		await reloadFromServer()
	}

	private func reloadFromServer() async {
		guard let catalogue = try? await service.eventTags(),
		      let updatedSection = catalogue.sections.first(where: { $0.id == section.id })
		else {
			return
		}

		tags = updatedSection.tags
	}
}
