import SwiftUI

struct AdministrationSpecialBadgesView: View {
	@State private var service = AdministrationService.shared
	@State private var badges: [AdministrationSpecialBadgeResponse] = []
	@State private var users: [AdministrationUserResponse] = []
	@State private var badgeOrder: [UUID] = []
	@State private var editor: AdministrationSpecialBadgeEditorTarget?
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		ScrollView {
			LazyVStack(spacing: 10) {
				ForEach(displayedBadges) { badge in
					Button {
						editor = .edit(badge)
					} label: {
						HStack(spacing: 12) {
							badgePreview(badge)

							VStack(alignment: .leading, spacing: 4) {
								Text(badge.accessibilityLabel)
								Text("\(badge.assignedUserIDs.count) users")
									.font(.footnote)
									.foregroundStyle(.secondary)
							}

							Spacer()
							Image(systemName: "line.3.horizontal")
								.foregroundStyle(.secondary)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, 14)
						.padding(.vertical, 10)
						.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
					}
					.buttonStyle(.plain)
					.contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
				}
				.reorderable()
			}
			.reorderContainer(for: AdministrationSpecialBadgeResponse.self) { difference in
				var reorderedBadges = displayedBadges
				difference.apply(to: &reorderedBadges)
				badgeOrder = reorderedBadges.map(\.id)
				saveBadgeOrder(badgeOrder)
			}
			.padding()
		}
		.appNavigationTitle("Badges", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Add Badge", systemImage: "plus", role: .confirm) {
					editor = .create
				}
				.foregroundStyle(.white)
				.buttonStyle(.glassProminent)
			}
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.sheet(item: $editor) { target in
			AdministrationSpecialBadgeEditor(
				target: target,
				users: users,
				save: save,
				delete: delete,
				close: { editor = nil }
			)
		}
	}

	private func badgePreview(_ badge: AdministrationSpecialBadgeResponse) -> some View {
		Image(systemName: badge.symbol)
			.font(.title3.weight(.bold))
			.foregroundStyle(badge.symbolColor?.swiftUIColor ?? .white)
			.frame(width: 40, height: 40)
			.background(badge.backgroundColor?.swiftUIColor ?? .black, in: Circle())
			.overlay {
				Circle()
					.stroke(.white, lineWidth: 0.5)
			}
	}

	private var displayedBadges: [AdministrationSpecialBadgeResponse] {
		let allBadges = allAvailableBadges
		guard !badgeOrder.isEmpty else {
			return allBadges
		}

		let knownBadges = Dictionary(uniqueKeysWithValues: allBadges.map { ($0.id, $0) })
		let orderedIDs = badgeOrder.filter { knownBadges[$0] != nil }
		let remaining = allBadges.filter { !orderedIDs.contains($0.id) }
		return orderedIDs.compactMap { knownBadges[$0] } + remaining
	}

	private var allAvailableBadges: [AdministrationSpecialBadgeResponse] {
		[
			administrationBadge(for: .systemOwner),
			administrationBadge(for: .administrator),
		] + badges
	}

	private func administrationBadge(for authority: AccountAuthority) -> AdministrationSpecialBadgeResponse {
		let badge = BuiltInProfileBadgeConfiguration.badge(for: authority)!
		return AdministrationSpecialBadgeResponse(
			id: badge.id,
			symbol: badge.symbol,
			backgroundColor: badge.backgroundColor,
			symbolColor: badge.symbolColor,
			priority: badge.priority,
			accessibilityLabel: badge.accessibilityLabel,
			assignedUserIDs: users
				.filter { $0.authority == authority }
				.map(\.id)
		)
	}

	private func load() async {
		do {
			badges = try await service.specialBadges()
		} catch {
			statusBadges.present(error: error, title: "Unable to load badges")
		}

		do {
			users = try await service.users()
		} catch {
			statusBadges.present(error: error, title: "Unable to load badge users")
		}

		if badgeOrder.isEmpty {
			badgeOrder = allAvailableBadges.map(\.id)
		} else {
			let knownIDs = Set(allAvailableBadges.map(\.id))
			let existingIDs = Set(badgeOrder)
			badgeOrder = badgeOrder.filter { knownIDs.contains($0) }
				+ allAvailableBadges.map(\.id).filter { !existingIDs.contains($0) }
		}
	}

	private func saveBadgeOrder(_ orderedIDs: [UUID]) {
		for (index, badgeID) in orderedIDs.enumerated() {
			guard BuiltInProfileBadgeConfiguration.authority(for: badgeID) != nil,
			      let badge = allAvailableBadges.first(where: { $0.id == badgeID })
			else {
				continue
			}

			BuiltInProfileBadgeConfiguration.update(
				ProfileBadge(
					id: badge.id,
					symbol: badge.symbol,
					backgroundColor: badge.backgroundColor,
					symbolColor: badge.symbolColor,
					priority: orderedIDs.count - index,
					accessibilityLabel: badge.accessibilityLabel
				)
			)
		}

		Task {
			let customBadgeIDs = orderedIDs.filter { BuiltInProfileBadgeConfiguration.authority(for: $0) == nil }
			do {
				badges = try await service.reorderSpecialBadges(badgeIDs: customBadgeIDs)
			} catch {
				statusBadges.present(error: error, title: "Unable to save badge order")
				badgeOrder = []
				await load()
			}
		}
	}

	private func save(
		_ request: AdministrationSpecialBadgeRequest,
		id: UUID?,
		userIDs: Set<UUID>
	) async throws -> AdministrationSpecialBadgeResponse {
		if let id, let builtInAuthority = BuiltInProfileBadgeConfiguration.authority(for: id) {
			BuiltInProfileBadgeConfiguration.update(
				ProfileBadge(
					id: id,
					symbol: request.symbol,
					backgroundColor: request.backgroundColor,
					symbolColor: request.symbolColor,
					priority: request.priority,
					accessibilityLabel: request.accessibilityLabel
				)
			)
			badgeOrder = displayedBadges.map(\.id)
			return administrationBadge(for: builtInAuthority)
		}

		let savedBadge = if let id {
			try await service.updateSpecialBadge(id: id, request: request)
		} else {
			try await service.createSpecialBadge(request)
		}
		let assignedBadge = try await service.replaceSpecialBadgeUsers(
			id: savedBadge.id,
			userIDs: userIDs
		)

		if let index = badges.firstIndex(where: { $0.id == assignedBadge.id }) {
			badges[index] = assignedBadge
		} else {
			badges.append(assignedBadge)
		}
		if !badgeOrder.contains(assignedBadge.id) {
			badgeOrder.append(assignedBadge.id)
		}

		let customBadgeIDs = badgeOrder.filter { BuiltInProfileBadgeConfiguration.authority(for: $0) == nil }
		badges = try await service.reorderSpecialBadges(badgeIDs: customBadgeIDs)
		return badges.first(where: { $0.id == assignedBadge.id }) ?? assignedBadge
	}

	private func delete(_ badge: AdministrationSpecialBadgeResponse) async throws {
		try await service.deleteSpecialBadge(id: badge.id)
		badges.removeAll { $0.id == badge.id }
		badgeOrder.removeAll { $0 == badge.id }
	}
}

private extension ReorderDifference where CollectionID == ReorderableSingleCollectionIdentifier {
	func apply<C: RangeReplaceableCollection>(to collection: inout C)
		where C.Element: Identifiable,
		C.Element.ID == ItemID
	{
		let moving = Set(sources)
		guard !moving.isEmpty else {
			return
		}

		var moved: [C.Element] = []
		moved.reserveCapacity(moving.count)
		collection.removeAll { element in
			guard moving.contains(element.id) else {
				return false
			}

			moved.append(element)
			return true
		}

		switch destination.position {
			case let .before(id):
				let index = collection.firstIndex { $0.id == id } ?? collection.endIndex
				collection.insert(contentsOf: moved, at: index)
			case .end:
				collection.append(contentsOf: moved)
		}
	}
}

enum AdministrationSpecialBadgeEditorTarget: Identifiable {
	case create
	case edit(AdministrationSpecialBadgeResponse)

	var id: String {
		switch self {
			case .create:
				"special-badge-create"
			case let .edit(badge):
				"special-badge-\(badge.id.uuidString)"
		}
	}

	var badge: AdministrationSpecialBadgeResponse? {
		if case let .edit(badge) = self {
			return badge
		}

		return nil
	}
}
