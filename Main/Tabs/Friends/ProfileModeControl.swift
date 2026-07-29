import SwiftUI

struct ProfileModeControl: View {
	@Binding var selection: ProfileContentKind
	let presentsBackground: Bool
	let showBackground: () -> Void

	var body: some View {
		HStack(spacing: 8) {
			Menu {
				Button("Photo", systemImage: "photo") {
					selection = .photo
				}
				Button("Monogram", systemImage: "character") {
					selection = .monogram
				}
				Button("Emoji", systemImage: "face.smiling") {
					selection = .emoji
				}
			} label: {
				Label(selection.title, systemImage: selection.symbol)
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.glass)

			if presentsBackground {
				Button("Background", systemImage: "paintpalette", action: showBackground)
					.labelStyle(.iconOnly)
					.buttonStyle(.glass)
					.transition(.blurReplace.combined(with: .opacity))
			}
		}
		.animation(.snappy, value: presentsBackground)
	}
}

private extension ProfileContentKind {
	var title: String {
		switch self {
			case .photo:
				"Photo"
			case .monogram:
				"Monogram"
			case .emoji:
				"Emoji"
		}
	}

	var symbol: String {
		switch self {
			case .photo:
				"photo"
			case .monogram:
				"character"
			case .emoji:
				"face.smiling"
		}
	}
}
