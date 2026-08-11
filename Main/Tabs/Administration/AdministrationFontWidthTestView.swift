import SwiftUI

struct AdministrationFontWidthTestView: View {
	private let sampleText = "Default Typography 0123456789"

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				Text("Default Font Widths")
					.font(.title.bold())

				Text("The system default font with each available SwiftUI width.")
					.foregroundStyle(.secondary)

				ForEach(FontWidthTestOption.allCases) { option in
					VStack(alignment: .leading, spacing: 4) {
						Text(option.title)
							.font(.caption)
							.foregroundStyle(.secondary)

						Text(sampleText)
							.font(.system(size: 30))
							.fontWidth(option.width)
					}
				}
			}
			.padding()
		}
		.appPaperBackground()
		.fontDesign(.default)
		.fontWidth(.standard)
		.appNavigationTitle("Font Width Test", accent: true)
	}
}

private enum FontWidthTestOption: String, CaseIterable, Identifiable {
	case compressed
	case condensed
	case standard
	case expanded

	var id: String {
		rawValue
	}

	var title: String {
		rawValue.capitalized
	}

	var width: Font.Width {
		switch self {
			case .compressed:
				.compressed
			case .condensed:
				.condensed
			case .standard:
				.standard
			case .expanded:
				.expanded
		}
	}
}
