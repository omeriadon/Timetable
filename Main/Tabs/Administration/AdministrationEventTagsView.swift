import SwiftUI

struct AdministrationEventTagsView: View {
	let closeWideDestination: (() -> Void)?
	@State private var service = AdministrationService.shared
	@State private var catalogue = AdministrationEventTagCatalogueResponse(sections: [])
	@State private var tags: [AdministrationEventTag] = []
	@State private var editor: AdministrationEventTagEditorTarget?
	@State private var isReordering = false
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation

	var body: some View {
		List {
			ForEach(tags) { tag in
				if let section = section(for: tag) {
					Group {
						if presentation == .iOS {
							Button {
								editor = .tag(tag, section: section)
							} label: {
								tagLabel(tag)
							}
							.buttonStyle(.plain)
						} else {
							NavigationLink {
								AdministrationEventTagEditor(
									tag: tag,
									section: section,
									save: saveTag,
									delete: deleteTag,
									close: closeWideEditor
								)
							} label: {
								tagLabel(tag)
							}
						}
					}
					.opacity(tag.isArchived ? 0.55 : 1)
				}
			}
			.onMove(perform: move)
		}

		.environment(\.editMode, .constant(isReordering ? .active : .inactive))
		.appNavigationTitle("Event Tags", accent: true)
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				if presentation == .iOS {
					Button("Add Tag", systemImage: "plus") {
						if let addableSection {
							editor = .newTag(addableSection)
						}
					}
					.disabled(addableSection == nil)
				} else if let addableSection {
					NavigationLink {
						AdministrationEventTagEditor(
							tag: nil,
							section: addableSection,
							save: saveTag,
							delete: deleteTag,
							close: closeWideEditor
						)
					} label: {
						Label("Add Tag", systemImage: "plus")
					}
				}
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
			ZStack {
				switch target {
					case let .tag(tag, section):
						AdministrationEventTagEditor(
							tag: tag,
							section: section,
							save: saveTag,
							delete: deleteTag,
							close: { editor = nil }
						)
					case let .newTag(section):
						AdministrationEventTagEditor(
							tag: nil,
							section: section,
							save: saveTag,
							delete: deleteTag,
							close: { editor = nil }
						)
				}
			}
		}
	}

	private func closeWideEditor() {
		closeWideDestination?()
	}

	private func tagLabel(_ tag: AdministrationEventTag) -> some View {
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

	private var addableSection: AdministrationEventTagSection? {
		catalogue.sections.first {
			$0.category == .general && !$0.isArchived
		}
	}

	private func section(for tag: AdministrationEventTag) -> AdministrationEventTagSection? {
		catalogue.sections.first { $0.id == tag.sectionID }
	}

	private func move(from offsets: IndexSet, to destination: Int) {
		tags.move(fromOffsets: offsets, toOffset: destination)
		Task {
			do {
				try await apply(
					service.reorderEventTags(
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
			try await apply(service.eventTags())
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

	private func deleteTag(_ id: UUID) async throws {
		let updated = try await service.deleteEventTag(id: id)
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
