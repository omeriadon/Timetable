import SwiftUI

struct AdministrationEventTagsView: View {
	@State private var service = AdministrationService.shared
	@State private var catalogue = AdministrationEventTagCatalogueResponse(sections: [])
	@State private var tags: [AdministrationEventTag] = []
	@State private var editor: AdministrationEventTagEditorTarget?
	@State private var isReordering = false
	@Environment(\.statusBadgeManager) private var badges
	@Namespace private var editorNamespace

	var body: some View {
		List {
			ForEach(tags) { tag in
				if let section = section(for: tag) {
					Button {
						editor = .tag(tag, section: section)
					} label: {
						Label {
							VStack(alignment: .leading, spacing: 3) {
								Text(tag.displayName)
								Text(tag.category.displayName)
									.font(.footnote)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: tag.symbol ?? "tag")
								.foregroundStyle(
									RGBAColor(hexString: tag.colorHex ?? "#6AA7FF").swiftUIColor
								)
						}
					}
					.buttonStyle(.plain)
					.opacity(tag.isArchived ? 0.55 : 1)
					.matchedTransitionSource(
						id: AdministrationEventTagEditorTarget.tag(tag, section: section).id,
						in: editorNamespace
					)
				}
			}
			.onMove(perform: move)
		}
		.environment(\.editMode, .constant(isReordering ? .active : .inactive))
		.appNavigationTitle("Event Tags", accent: true)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Menu {
					ForEach(addableSections) { section in
						Button("Add \(section.displayName)", systemImage: "plus") {
							editor = .newTag(section)
						}
					}
				} label: {
					Label("Add Tag", systemImage: "plus")
				}
				.disabled(addableSections.isEmpty)
			}

			ToolbarItem(placement: .confirmationAction) {
				Button(
					isReordering ? "Done" : "Reorder",
					systemImage: isReordering ? "checkmark" : "arrow.up.arrow.down"
				) {
					isReordering.toggle()
				}
			}
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.sheet(item: $editor) { target in
			switch target {
				case let .tag(tag, section):
					AdministrationEventTagEditor(
						tag: tag,
						section: section,
						save: saveTag
					)
				case let .newTag(section):
					AdministrationEventTagEditor(
						tag: nil,
						section: section,
						save: saveTag
					)
			}
			.navigationTransition(
				.zoom(
					sourceID: target.id,
					in: editorNamespace
				)
			)
		}
	}

	private var addableSections: [AdministrationEventTagSection] {
		catalogue.sections.filter {
			$0.category != .yearGroup && !$0.isArchived
		}
	}

	private func section(for tag: AdministrationEventTag) -> AdministrationEventTagSection? {
		catalogue.sections.first { $0.id == tag.sectionID }
	}

	private func move(from offsets: IndexSet, to destination: Int) {
		tags.move(fromOffsets: offsets, toOffset: destination)
		Task {
			do {
				apply(
					try await service.reorderEventTags(
						tagIDs: tags.map(\.id)
					)
				)
			} catch {
				badges.present(error: error, title: "Unable to reorder event tags")
				await load()
			}
		}
	}

	private func load() async {
		do {
			apply(try await service.eventTags())
		} catch {
			badges.present(error: error, title: "Unable to refresh event tags")
		}
	}

	private func saveTag(
		_ request: AdministrationEventTagRequest,
		existingID: UUID?
	) async throws {
		let updated = if let existingID {
			try await service.updateEventTag(id: existingID, request: request)
		} else {
			try await service.createEventTag(request)
		}
		apply(updated)
	}

	private func apply(_ catalogue: AdministrationEventTagCatalogueResponse) {
		self.catalogue = catalogue
		tags = catalogue.sections
			.flatMap(\.tags)
			.sorted {
				if $0.sortOrder == $1.sortOrder {
					return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
				}
				return $0.sortOrder < $1.sortOrder
			}
	}
}

enum AdministrationEventTagEditorTarget: Identifiable {
	case tag(AdministrationEventTag, section: AdministrationEventTagSection)
	case newTag(AdministrationEventTagSection)

	var id: String {
		switch self {
			case let .tag(tag, _):
				"tag-\(tag.id.uuidString)"
			case let .newTag(section):
				"new-tag-\(section.id.uuidString)"
		}
	}
}
