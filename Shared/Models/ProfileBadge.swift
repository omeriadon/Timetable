import Foundation

nonisolated struct ProfileBadge: Codable, Hashable, Identifiable, Sendable {
	let id: UUID
	let symbol: String
	let backgroundColor: RGBAColor?
	let symbolColor: RGBAColor?
	let priority: Int
	let accessibilityLabel: String

	init(
		id: UUID = UUID(),
		symbol: String,
		backgroundColor: RGBAColor? = nil,
		symbolColor: RGBAColor? = nil,
		priority: Int,
		accessibilityLabel: String
	) {
		self.id = id
		self.symbol = symbol
		self.backgroundColor = backgroundColor
		self.symbolColor = symbolColor
		self.priority = priority
		self.accessibilityLabel = accessibilityLabel
	}
}

nonisolated enum BuiltInProfileBadgeConfiguration {
	static let systemOwnerID = UUID(uuidString: "E93DD9C4-A5B1-4694-9795-FD0D89C05FB3")!
	static let administratorID = UUID(uuidString: "0F6CD452-84AC-4482-8C23-A48F5D56148A")!

	private static let systemOwnerKey = "profile-badge.system-owner"
	private static let administratorKey = "profile-badge.administrator"

	static func badge(for authority: AccountAuthority) -> ProfileBadge? {
		switch authority {
			case .systemOwner:
				storedBadge(forKey: systemOwnerKey) ?? ProfileBadge(
					id: systemOwnerID,
					symbol: "wrench.and.screwdriver",
					backgroundColor: RGBAColor(red: 0, green: 0, blue: 0, alpha: 1),
					symbolColor: RGBAColor(red: 1, green: 1, blue: 1, alpha: 1),
					priority: 100,
					accessibilityLabel: "System Administrator"
				)
			case .administrator:
				storedBadge(forKey: administratorKey) ?? ProfileBadge(
					id: administratorID,
					symbol: "book.and.wrench",
					backgroundColor: RGBAColor(red: 0.16, green: 0.45, blue: 0.95, alpha: 1),
					symbolColor: RGBAColor(red: 1, green: 1, blue: 1, alpha: 1),
					priority: 90,
					accessibilityLabel: "Administrator"
				)
			case .user:
				nil
		}
	}

	static func authority(for id: UUID) -> AccountAuthority? {
		switch id {
			case systemOwnerID:
				.systemOwner
			case administratorID:
				.administrator
			default:
				nil
		}
	}

	static func update(_ badge: ProfileBadge) {
		guard let authority = authority(for: badge.id) else {
			return
		}

		let key = authority == .systemOwner ? systemOwnerKey : administratorKey
		guard let data = try? JSONEncoder().encode(badge) else {
			return
		}

		UserDefaults.standard.set(data, forKey: key)
	}

	private static func storedBadge(forKey key: String) -> ProfileBadge? {
		guard let data = UserDefaults.standard.data(forKey: key) else {
			return nil
		}

		return try? JSONDecoder().decode(ProfileBadge.self, from: data)
	}
}
