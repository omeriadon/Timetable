import SwiftUI

struct AdministrationSpecialBadgesView: View {
	@State private var service = AdministrationService.shared
	@State private var badges: [AdministrationSpecialBadgeResponse] = []
	@State private var users: [AdministrationUserResponse] = []
	@State private var editor: AdministrationSpecialBadgeEditorTarget?
	@Environment(\.statusBadgeManager) private var statusBadges
	@Namespace private var namespace

	var body: some View {
		List {
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
					}
				}
				.buttonStyle(.plain)
				.matchedTransitionSource(id: editorID(for: badge), in: namespace)
			}
		}
		.appNavigationTitle("Special Badges", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Add Badge", systemImage: "plus", role: .confirm) {
					editor = .create
				}
				.foregroundStyle(.white)
				.buttonStyle(.glassProminent)
				.matchedTransitionSource(id: "special-badge-create", in: namespace)
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
				delete: delete
			)
			.navigationTransition(
				.zoom(
					sourceID: target.id,
					in: namespace
				)
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

	private func editorID(for badge: AdministrationSpecialBadgeResponse) -> String {
		"special-badge-\(badge.id.uuidString)"
	}

	private var displayedBadges: [AdministrationSpecialBadgeResponse] {
		[
			administrationBadge(for: .systemOwner),
			administrationBadge(for: .administrator)
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
			assignedUserIDs: []
		)
	}

	private func load() async {
		do {
			badges = try await service.specialBadges()
		} catch {
			statusBadges.present(error: error, title: "Unable to load special badges")
		}

		do {
			users = try await service.users()
		} catch {
			statusBadges.present(error: error, title: "Unable to load badge users")
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
		badges.sort { $0.priority > $1.priority }
		return assignedBadge
	}

	private func delete(_ badge: AdministrationSpecialBadgeResponse) async throws {
		try await service.deleteSpecialBadge(id: badge.id)
		badges.removeAll { $0.id == badge.id }
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
