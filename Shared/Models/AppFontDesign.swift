import SwiftUI

nonisolated enum AppFontDesign: String, Codable, CaseIterable, Identifiable, Sendable {
	case monospaced
	case rounded
	case expanded

	var id: String {
		rawValue
	}

	var title: String {
		rawValue.capitalized
	}

	var swiftUIFontDesign: Font.Design {
		switch self {
			case .monospaced:
				.monospaced
			case .rounded:
				.rounded
			case .expanded:
				.default
		}
	}

	var swiftUIFontWidth: Font.Width {
		switch self {
			case .monospaced:
				.standard
			case .rounded:
				.expanded
			case .expanded:
				.expanded
		}
	}
}
