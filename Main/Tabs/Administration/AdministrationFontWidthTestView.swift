import SwiftUI

struct AdministrationFontWidthTestView: View {
	private let sampleText = "Rounded Typography 0123456789"

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				fontFamilySection(
					title: "SwiftUI Rounded Design",
					subtitle: "The app’s current rounded design with each available width.",
					font: { size in Font.system(size: size, design: .rounded) }
				)

				fontFamilySection(
					title: "SF Pro Rounded",
					subtitle: "Raw font family.",
					font: { size in Font.custom("SF Pro Rounded", size: size) }
				)

				fontFamilySection(
					title: "SF Compact Rounded",
					subtitle: "Raw font family.",
					font: { size in Font.custom("SF Compact Rounded", size: size) }
				)
			}
			.padding()
		}
		.appNavigationTitle("Font Width Test", accent: true)
	}

	@ViewBuilder
	private func fontFamilySection(
		title: String,
		subtitle: String,
		font: (CGFloat) -> Font
	) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(title)
				.font(.title2.bold())

			Text(subtitle)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			ForEach(FontWidthTestOption.allCases) { option in
				VStack(alignment: .leading, spacing: 3) {
					Text(option.title)
						.font(.caption)
						.foregroundStyle(.secondary)

					Text(sampleText)
						.font(font(30))
						.fontWidth(option.width)
				}
			}
		}
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
