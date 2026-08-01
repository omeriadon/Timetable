import SwiftUI

struct AdministrationEventTagsView: View {
	@State private var service = AdministrationService.shared
	@State private var catalogue = AdministrationEventTagCatalogueResponse(sections: [])
	@State private var editor: AdministrationEventTagEditorTarget?
	@Environment(\.statusBadgeManager) private var badges
	@Namespace private var editorNamespace

	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 22) {
				ForEach(catalogue.sections) { section in
					sectionView(section)
						.padding(5)
						.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
						.opacity(section.isArchived ? 0.55 : 1)
				}
				.padding()
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
			Group {
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
					case let .section(section):
						AdministrationEventTagSectionEditor(
							section: section,
							save: saveSection,
							saveTag: saveTag
						)
				}
			}
			.navigationTransition(
				.zoom(
					sourceID: target.id,
					in: editorNamespace
				)
			)
		}
	}

	private func sectionView(_ section: AdministrationEventTagSection) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 12) {
				Label {
					VStack(alignment: .leading, spacing: 4) {
						Text(section.displayName)
						Text(section.category.displayName)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				} icon: {
					Image(systemName: section.isArchived ? "archivebox" : "folder")
						.foregroundStyle(.accent)
				}

				Spacer()

				Button("Edit Section", systemImage: "slider.horizontal.3") {
					editor = .section(section)
				}
				.labelStyle(.iconOnly)
				.buttonStyle(.borderless)
				.foregroundStyle(.white)
				.matchedTransitionSource(
					id: AdministrationEventTagEditorTarget.section(section).id,
					in: editorNamespace
				)
			}

			WrappingHStack(spacing: 8, lineSpacing: 8) {
				ForEach(section.tags) { tag in
					Button {
						editor = .tag(tag, section: section)
					} label: {
						Label(tag.displayName, systemImage: tag.symbol ?? "tag")
							.padding(.horizontal, 12)
							.padding(.vertical, 8)
					}
					.buttonStyle(.glassProminent)
					.foregroundStyle(.white)
					.tint(RGBAColor(hexString: tag.colorHex ?? "fff").swiftUIColor)
					.opacity(tag.isArchived ? 0.55 : 1)
					.matchedTransitionSource(
						id: AdministrationEventTagEditorTarget.tag(tag, section: section).id,
						in: editorNamespace
					)
				}

				if section.category != .yearGroup {
					Button("Add Tag", systemImage: "plus") {
						editor = .newTag(section)
					}
					.buttonStyle(.glass)
					.foregroundStyle(.white)
					.matchedTransitionSource(
						id: AdministrationEventTagEditorTarget.newTag(section).id,
						in: editorNamespace
					)
				}
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
		_ request: AdministrationEventTagSectionUpdateRequest,
		existingID: UUID
	) async throws {
		catalogue = try await service.updateEventTagSection(id: existingID, request: request)
	}
}

private struct WrappingHStack: Layout {
	let spacing: CGFloat
	let lineSpacing: CGFloat

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache _: inout Cache
	) -> CGSize {
		layoutResult(proposal: proposal, subviews: subviews).size
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal _: ProposedViewSize,
		subviews: Subviews,
		cache _: inout Cache
	) {
		let result = layoutResult(
			proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
			subviews: subviews
		)

		for (index, point) in result.positions.enumerated() {
			subviews[index].place(
				at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
				anchor: .topLeading,
				proposal: ProposedViewSize(result.sizes[index])
			)
		}
	}

	private func layoutResult(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
		let availableWidth = proposal.width ?? .infinity
		var positions: [CGPoint] = []
		var sizes: [CGSize] = []
		var currentX: CGFloat = 0
		var currentY: CGFloat = 0
		var lineHeight: CGFloat = 0
		var contentWidth: CGFloat = 0

		for subview in subviews {
			let size = subview.sizeThatFits(ProposedViewSize(width: availableWidth, height: nil))
			if currentX > 0, currentX + size.width > availableWidth {
				currentX = 0
				currentY += lineHeight + lineSpacing
				lineHeight = 0
			}

			positions.append(CGPoint(x: currentX, y: currentY))
			sizes.append(size)
			currentX += size.width + spacing
			lineHeight = max(lineHeight, size.height)
			contentWidth = max(contentWidth, currentX - spacing)
		}

		return LayoutResult(
			size: CGSize(width: min(contentWidth, availableWidth), height: currentY + lineHeight),
			positions: positions,
			sizes: sizes
		)
	}

	private struct LayoutResult {
		let size: CGSize
		let positions: [CGPoint]
		let sizes: [CGSize]
	}
}

enum AdministrationEventTagEditorTarget: Identifiable {
	case tag(AdministrationEventTag, section: AdministrationEventTagSection)
	case newTag(AdministrationEventTagSection)
	case section(AdministrationEventTagSection)

	var id: String {
		switch self {
			case let .tag(tag, _):
				"tag-\(tag.id.uuidString)"
			case let .newTag(section):
				"new-tag-\(section.id.uuidString)"
			case let .section(section):
				"section-\(section.id.uuidString)"
		}
	}
}
