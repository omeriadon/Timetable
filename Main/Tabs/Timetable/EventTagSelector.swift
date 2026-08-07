import SwiftUI

struct EventTagSelector: View {
	let sections: [EventTagCatalogueSection]
	let allowsYearGroups: Bool
	@Binding var selectedTagIDs: Set<UUID>

	var body: some View {
		NavigationLink {
			EventTagSelectionView(
				sections: availableSections,
				allowsYearGroups: allowsYearGroups,
				selectedTagIDs: $selectedTagIDs
			)
		} label: {
			Label("Tags", systemImage: "tag")
		}
	}

	private var availableSections: [EventTagCatalogueSection] {
		sections.filter { allowsYearGroups || $0.category != .yearGroup }
	}
}

private struct EventTagSelectionView: View {
	let sections: [EventTagCatalogueSection]
	let allowsYearGroups: Bool
	@Binding var selectedTagIDs: Set<UUID>

	var body: some View {
		List {
			if allowsYearGroups, !yearGroupTags.isEmpty {
				Section("Year Groups") {
					ForEach(yearGroupTags) { tag in
						tagRow(tag)
					}
				}
			}

			Section {
				ForEach(otherTags) { tag in
					tagRow(tag)
				}
			}
		}
		.listStyle(.sidebar)
		.appNavigationTitle("Tags")
	}

	private var availableTags: [EventTagCatalogueTag] {
		sections.flatMap(\.tags)
	}

	private var yearGroupTags: [EventTagCatalogueTag] {
		availableTags.filter { $0.category == .yearGroup }
	}

	private var otherTags: [EventTagCatalogueTag] {
		availableTags.filter { $0.category != .yearGroup }
	}

	private func tagRow(_ tag: EventTagCatalogueTag) -> some View {
		let isSelected = selectedTagIDs.contains(tag.id)
		return Button {
			toggle(tag)
		} label: {
			HStack {
				Image(systemName: tag.symbol ?? "tag")
					.foregroundStyle(.white)
				Text(tag.displayName)
					.foregroundStyle(isSelected ? .white : .primary)
				Spacer()
				if isSelected {
					Image(systemName: "checkmark")
						.foregroundStyle(.white)
				}
			}
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.listRowBackground(isSelected ? Color.accentColor : nil)
		.animation(.snappy(duration: 0.1), value: isSelected)
		.accessibilityAddTraits(isSelected ? .isSelected : [])
	}

	private var yearGroupTagIDs: Set<UUID> {
		Set(
			sections
				.filter { $0.category == .yearGroup }
				.flatMap(\.tags)
				.map(\.id)
		)
	}

	private func toggle(_ tag: EventTagCatalogueTag) {
		withAnimation(.snappy) {
			if tag.category == .yearGroup, allowsYearGroups {
				selectedTagIDs.subtract(yearGroupTagIDs)
				selectedTagIDs.insert(tag.id)
			} else if selectedTagIDs.contains(tag.id) {
				selectedTagIDs.remove(tag.id)
			} else {
				selectedTagIDs.insert(tag.id)
			}
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
