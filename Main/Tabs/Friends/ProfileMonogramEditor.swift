import SwiftUI

extension ProfileFontDesign {
	var swiftUIFontDesign: Font.Design {
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
}

extension ProfileFontWeight {
	var swiftUIFontWeight: Font.Weight {
		switch self {
			case .regular:
				.regular
			case .medium:
				.medium
			case .semibold:
				.semibold
			case .bold:
				.bold
			case .heavy:
				.heavy
		}
	}
}
