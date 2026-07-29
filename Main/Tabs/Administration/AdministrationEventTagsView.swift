import SwiftUI

struct AdministrationEventTagsView: View {
	@State private var service = AdministrationService.shared
	@State private var catalogue = AdministrationEventTagCatalogueResponse(sections: [])
	@State private var editor: AdministrationEventTagEditorTarget?
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			ForEach(catalogue.sections) { section in
				DisclosureGroup {
					ForEach(section.tags) { tag in
						Button {
							editor = .tag(tag, section: section)
						} label: {
							Label {
								VStack(alignment: .leading, spacing: 4) {
									Text(tag.displayName)
										.foregroundStyle(.primary)
									Text(tag.slug)
										.font(.footnote.monospaced())
										.foregroundStyle(.secondary)
								}
							} icon: {
								Image(systemName: tag.symbol ?? "tag")
							}
							.padding(.vertical, 4)
						}
						.buttonStyle(.plain)
						.opacity(tag.isArchived ? 0.55 : 1)
					}

					Button("Add Tag", systemImage: "plus") {
						editor = .newTag(section)
					}
				} label: {
					HStack(spacing: 12) {
						Image(systemName: section.isArchived ? "archivebox" : "folder")
						VStack(alignment: .leading, spacing: 4) {
							Text(section.displayName)
							Text(section.category.displayName)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
						Spacer()
						Button("Edit Section", systemImage: "slider.horizontal.3") {
							editor = .section(section)
						}
						.buttonStyle(.borderless)
					}
				}
				.opacity(section.isArchived ? 0.55 : 1)
			}

			Button("Add Section", systemImage: "folder.badge.plus") {
				editor = .newSection
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Event Tags", accent: true)
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
						sections: catalogue.sections,
						save: saveTag
					)
				case let .newTag(section):
					AdministrationEventTagEditor(
						tag: nil,
						section: section,
						sections: catalogue.sections,
						save: saveTag
					)
				case let .section(section):
					AdministrationEventTagSectionEditor(
						section: section,
						save: saveSection
					)
				case .newSection:
					AdministrationEventTagSectionEditor(
						section: nil,
						save: saveSection
					)
			}
		}
	}

	private func load() async {
		do {
			catalogue = try await service.eventTags()
		} catch {
			badges.present(error: error, title: "Unable to refresh event tags")
		}
	}

	private func saveTag(
		_ request: AdministrationEventTagRequest,
		existingID: UUID?
	) async throws {
		catalogue = if let existingID {
			try await service.updateEventTag(id: existingID, request: request)
		} else {
			try await service.createEventTag(request)
		}
	}

	private func saveSection(
		_ createRequest: AdministrationEventTagSectionCreateRequest?,
		_ updateRequest: AdministrationEventTagSectionUpdateRequest?,
		existingID: UUID?
	) async throws {
		if let existingID, let updateRequest {
			catalogue = try await service.updateEventTagSection(id: existingID, request: updateRequest)
		} else if let createRequest {
			catalogue = try await service.createEventTagSection(createRequest)
		}
	}
}

enum AdministrationEventTagEditorTarget: Identifiable {
	case tag(AdministrationEventTag, section: AdministrationEventTagSection)
	case newTag(AdministrationEventTagSection)
	case section(AdministrationEventTagSection)
	case newSection

	var id: String {
		switch self {
			case let .tag(tag, _):
				"tag-\(tag.id.uuidString)"
			case let .newTag(section):
				"new-tag-\(section.id.uuidString)"
			case let .section(section):
				"section-\(section.id.uuidString)"
			case .newSection:
				"new-section"
		}
	}
}
