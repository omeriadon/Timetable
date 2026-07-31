import SwiftUI

nonisolated enum ProfileFontWeight: String, Codable, CaseIterable, Identifiable, Sendable {
	case ultraLight
	case thin
	case light
	case regular
	case medium
	case semibold
	case bold
	case heavy
	case black

	var id: String {
		rawValue
	}

	var profilePictureFontWeight: Font.Weight {
		switch self {
			case .ultraLight: .ultraLight
			case .thin: .thin
			case .light: .light
			case .regular: .regular
			case .medium: .medium
			case .semibold: .semibold
			case .bold: .bold
			case .heavy: .heavy
			case .black: .black
		}
	}

	var swiftUIFontWeight: Font.Weight {
		profilePictureFontWeight
	}
}
