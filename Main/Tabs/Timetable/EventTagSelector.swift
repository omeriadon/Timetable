import SwiftUI

struct EventTagSelector: View {
	let sections: [EventTagCatalogueSection]
	let allowsYearGroups: Bool
	@Binding var selectedTagIDs: Set<UUID>

	var body: some View {
		ForEach(sections) { section in
			if allowsYearGroups || section.category != .yearGroup {
				Section(section.displayName) {
					TagFlowLayout(spacing: 8) {
						ForEach(section.tags) { tag in
							Button {
								toggle(tag, in: section)
							} label: {
								Label(tag.displayName, systemImage: tag.symbol ?? "tag")
									.font(.subheadline.weight(.medium))
									.padding(.horizontal, 10)
									.padding(.vertical, 7)
									.background {
										Capsule()
											.fill(selectedTagIDs.contains(tag.id) ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.12))
									}
									.overlay {
										Capsule()
											.stroke(selectedTagIDs.contains(tag.id) ? Color.accentColor : Color.clear, lineWidth: 1)
									}
							}
							.buttonStyle(.plain)
							.accessibilityAddTraits(selectedTagIDs.contains(tag.id) ? .isSelected : [])
						}
					}
					.padding(.vertical, 4)
				}
			}
		}
	}

	private func toggle(_ tag: EventTagCatalogueTag, in section: EventTagCatalogueSection) {
		if section.category == .yearGroup, allowsYearGroups {
			selectedTagIDs.subtract(section.tags.map(\.id))
			selectedTagIDs.insert(tag.id)
		} else if selectedTagIDs.contains(tag.id) {
			selectedTagIDs.remove(tag.id)
		} else {
			selectedTagIDs.insert(tag.id)
		}
	}
}

struct TagFlowLayout: Layout {
	var spacing: CGFloat = 8

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache _: inout ()
	) -> CGSize {
		let maxWidth = proposal.width ?? .greatestFiniteMagnitude
		var width: CGFloat = 0
		var height: CGFloat = 0
		var rowHeight: CGFloat = 0

		for subview in subviews {
			let size = subview.sizeThatFits(.unspecified)
			if width > 0, width + spacing + size.width > maxWidth {
				height += rowHeight + spacing
				width = 0
				rowHeight = 0
			}
			width += (width > 0 ? spacing : 0) + size.width
			rowHeight = max(rowHeight, size.height)
		}

		return CGSize(width: proposal.width ?? width, height: height + rowHeight)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal _: ProposedViewSize,
		subviews: Subviews,
		cache _: inout ()
	) {
		var x = bounds.minX
		var y = bounds.minY
		var rowHeight: CGFloat = 0

		for subview in subviews {
			let size = subview.sizeThatFits(.unspecified)
			if x > bounds.minX, x + spacing + size.width > bounds.maxX {
				x = bounds.minX
				y += rowHeight + spacing
				rowHeight = 0
			}
			if x > bounds.minX {
				x += spacing
			}
			subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
			x += size.width
			rowHeight = max(rowHeight, size.height)
		}
	}
}
