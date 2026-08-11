import Defaults
import SwiftUI

struct TagSubscriptionsView: View {
	@State private var service = AdministrationService.shared
	@Default(.eventTagCatalogue) private var cachedCatalogue
	@Default(.eventTagSubscriptionIDs) private var cachedSubscriptionIDs
	@State private var sections: [EventTagCatalogueSection]
	@State private var selectedTagIDs: Set<UUID>
	@State private var committedTagIDs: Set<UUID>
	@State private var isSaving = false
	@Environment(\.statusBadgeManager) private var badges

	init() {
		let catalogue = Defaults[.eventTagCatalogue]
		let tagIDs = Set(Defaults[.eventTagSubscriptionIDs])
		_sections = State(initialValue: catalogue.sections)
		_selectedTagIDs = State(initialValue: tagIDs)
		_committedTagIDs = State(initialValue: tagIDs)
	}

	var body: some View {
		List {
			if !yearGroupTags.isEmpty {
				Section("Year Groups") {
					ForEach(yearGroupTags) { tag in
						tagToggle(tag)
					}
				}
				.glurListRowBackground()
			}

			Section("Other Tags") {
				ForEach(otherTags) { tag in
					tagToggle(tag)
				}
			}
			.glurListRowBackground()
		}
		.appPaperBackground()
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

	private var yearGroupTags: [EventTagCatalogueTag] {
		tags.filter { $0.category == .yearGroup }
	}

	private var otherTags: [EventTagCatalogueTag] {
		tags.filter { $0.category != .yearGroup }
	}

	private var tags: [EventTagCatalogueTag] {
		sections.flatMap(\.tags)
	}

	private func tagToggle(_ tag: EventTagCatalogueTag) -> some View {
		Toggle(isOn: Binding(
			get: { selectedTagIDs.contains(tag.id) },
			set: { setSubscription($0, for: tag) }
		)) {
			Label(tag.displayName, systemImage: tag.symbol ?? "tag")
				.tint(.accent)
		}
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
