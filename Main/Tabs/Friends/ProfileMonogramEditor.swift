import SwiftUI

struct ProfileMonogramEditor: View {
	@Binding var monogram: String
	let design: ProfileFontDesign
	let weight: ProfileFontWeight
	let colours: [RGBAColor]
	@FocusState private var isFocused: Bool

	var body: some View {
		ZStack {
			LinearGradient(
				colors: colours.map(\.swiftUIColor),
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			TextField("Initials", text: $monogram)
				.multilineTextAlignment(.center)
				.textInputAutocapitalization(.characters)
				.autocorrectionDisabled()
				.font(.system(size: 48, weight: weight.swiftUIFontWeight, design: design.swiftUIFontDesign))
				.foregroundStyle(.white)
				.tint(.white)
				.focused($isFocused)
				.accessibilityLabel("Profile monogram")
				.onChange(of: monogram) { _, value in
					let normalized = String(value.prefix(3)).uppercased()
					if normalized != value {
						monogram = normalized
					}
				}
		}
		.frame(width: 132, height: 132)
		.clipShape(.circle)
	}
}

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
