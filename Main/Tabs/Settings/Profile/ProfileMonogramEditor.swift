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
