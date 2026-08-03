import SwiftUI

struct TagSubscriptionsView: View {
	@State private var service = AdministrationService.shared
	@State private var sections: [EventTagCatalogueSection] = []
	@State private var selectedTagIDs: Set<UUID> = []
	@State private var committedTagIDs: Set<UUID> = []
	@State private var isSaving = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		Form {
			ForEach(tags) { tag in
				Toggle(isOn:
					Binding(
						get: { selectedTagIDs.contains(tag.id) },
						set: { isSelected in
							setSubscription(isSelected, for: tag)
						}
					)) {
						Label(tag.displayName, systemImage: tag.symbol ?? "tag")
							.tint(.accent)
					}
			}
		}
		.formStyle(.grouped)
		.scrollContentBackground(.hidden)
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

	private var tags: [EventTagCatalogueTag] {
		sections.flatMap(\.tags)
	}

	private var yearGroupTagIDs: Set<UUID> {
		Set(tags.lazy.filter { $0.category == .yearGroup }.map(\.id))
	}

	private func setSubscription(_ isSelected: Bool, for tag: EventTagCatalogueTag) {
		var proposed = selectedTagIDs
		if tag.category == .yearGroup {
			proposed.subtract(yearGroupTagIDs)
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
