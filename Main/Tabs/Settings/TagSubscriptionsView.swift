import SwiftUI

struct TagSubscriptionsView: View {
	@State private var service = AdministrationService.shared
	@State private var sections: [EventTagCatalogueSection] = []
	@State private var selectedTagIDs: Set<UUID> = []
	@State private var committedTagIDs: Set<UUID> = []
	@State private var isSaving = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			ForEach(sections) { section in
				Section(section.displayName) {
					ForEach(section.tags) { tag in
						Toggle(
							tag.displayName,
							isOn: Binding(
								get: { selectedTagIDs.contains(tag.id) },
								set: { isSelected in
									setSubscription(isSelected, for: tag, in: section)
								}
							)
						)
					}
				}
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
	}

	private func load() async {
		async let catalogue = service.tagCatalogue()
		async let subscriptions = service.tagSubscriptions()
		guard let loadedCatalogue = try? await catalogue, let loadedSubscriptions = try? await subscriptions else {
			return
		}

		sections = loadedCatalogue.sections
		selectedTagIDs = Set(loadedSubscriptions.tagIDs)
		committedTagIDs = selectedTagIDs
	}

	private func setSubscription(
		_ isSelected: Bool,
		for tag: EventTagCatalogueTag,
		in section: EventTagCatalogueSection
	) {
		var proposed = selectedTagIDs
		if section.category == .yearGroup {
			let yearTagIDs = Set(section.tags.map(\.id))
			proposed.subtract(yearTagIDs)
			if isSelected {
				proposed.insert(tag.id)
			}
		} else if isSelected {
			proposed.insert(tag.id)
		} else {
			proposed.remove(tag.id)
		}

		selectedTagIDs = proposed
		Task {
			await save(proposed)
		}
	}

	private func save(_ proposed: Set<UUID>) async {
		isSaving = true
		defer {
			isSaving = false
		}

		do {
			let response = try await service.replaceTagSubscriptions(proposed)
			selectedTagIDs = Set(response.tagIDs)
			committedTagIDs = selectedTagIDs
		} catch {
			selectedTagIDs = committedTagIDs
			badges.addBadge(
				id: UUID(),
				title: "Unable to save event tags",
				secondaryText: error.localizedDescription,
				priority: 4,
				view: .error
			)
		}
	}
}
