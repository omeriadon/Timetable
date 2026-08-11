import SwiftUI

struct ProfileFontPicker: View {
	let close: () -> Void = {}
	@Binding var design: ProfileFontDesign
	@Binding var weight: ProfileFontWeight

	var body: some View {
		List {
			Section("Design") {
				ForEach(ProfileFontDesign.allCases) { candidate in
					Button {
						design = candidate
					} label: {
						Label(candidate.title, systemImage: design == candidate ? "checkmark.circle.fill" : "circle")
							.contentTransition(.symbolEffect(.replace.wholeSymbol, options: .nonRepeating))
							.font(.system(.body, design: candidate.swiftUIFontDesign))
					}
				}
			}
			.glurListRowBackground()

			Section("Weight") {
				let allCases = ProfileFontWeight.allCases

				Slider(
					value: Binding(
						get: {
							Double(allCases.firstIndex(of: weight) ?? 0)
						},
						set: { newValue in
							let index = Int(round(newValue))
							if allCases.indices.contains(index) {
								weight = allCases[index]
							}
						}
					),
					in: 0 ... Double(allCases.count - 1),
					step: 1
				)
			}
			.glurListRowBackground()
		}
		.appPaperPresentation()
	}
}
