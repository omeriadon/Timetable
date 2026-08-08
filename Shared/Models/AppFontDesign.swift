import SwiftUI

nonisolated enum AppFontDesign: String, Codable, CaseIterable, Identifiable, Sendable {
	case monospaced
	case rounded

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
		}
	}

	var swiftUIFontWidth: Font.Width {
		switch self {
			case .monospaced:
				.standard
			case .rounded:
				.expanded
		}
	}
}
