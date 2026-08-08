import SwiftUI

struct AdministrationFontWidthTestView: View {
	private let sampleText = "Rounded Typography 0123456789"

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				Text("Rounded Font Faces")
					.font(.title.bold())

				Text("SF Pro Rounded and SF Compact Rounded do not expose real width instances. These rows render the actual font faces without width modifiers or transforms.")
					.foregroundStyle(.secondary)

				swiftUIRoundedSection
				fontFaceSection(
					title: "SF Pro Rounded Medium",
					postScriptName: "SFProRounded-Medium"
				)
				fontFaceSection(
					title: "SF Compact Rounded Regular",
					postScriptName: ".SFCompactRounded-Regular"
				)

			}
			.padding()
		}
		.fontDesign(.default)
		.fontWidth(.standard)
		.appNavigationTitle("Font Width Test", accent: true)
	}

	private var swiftUIRoundedSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("SwiftUI Rounded")
				.font(.title2.bold())

			Text("Font.system(design: .rounded)")
				.font(.subheadline)
				.foregroundStyle(.secondary)

			Text(sampleText)
				.font(.system(size: 30, design: .rounded))
		}
	}

	private func fontFaceSection(title: String, postScriptName: String) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(title)
				.font(.title2.bold())

			Text(postScriptName)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			Text(sampleText)
				.font(.custom(postScriptName, size: 30))
		}
	}
}
