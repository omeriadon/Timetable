import Foundation

nonisolated enum AppBackground: String, Codable, CaseIterable, Hashable, Identifiable {
	case solid
	case paper

	var id: Self {
		self
	}

	var title: String {
		switch self {
			case .solid:
				"Solid"
			case .paper:
				"Paper"
		}
	}

	var symbol: String {
		switch self {
			case .solid:
				"circle.lefthalf.filled"
			case .paper:
				"doc.text.image"
		}
	}

	init(from decoder: any Decoder) throws {
		let value = try decoder.singleValueContainer().decode(String.self)
		self = value == Self.solid.rawValue ? .solid : .paper
	}
}
