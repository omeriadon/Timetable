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
