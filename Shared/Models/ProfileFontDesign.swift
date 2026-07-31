import SwiftUI

nonisolated enum ProfileFontDesign: String, Codable, CaseIterable, Identifiable, Sendable {
	case `default`
	case serif
	case monospaced
	case rounded

	var id: String {
		rawValue
	}

	var profilePictureFontDesign: Font.Design {
		switch self {
			case .default:
				.default
			case .serif:
				.serif
			case .monospaced:
				.monospaced
			case .rounded:
				.rounded
		}
	}

	var title: String {
		rawValue.capitalized
	}
}
