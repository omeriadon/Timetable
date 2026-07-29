import SwiftUI

struct ProfileFontPicker: View {
	@Environment(\.dismiss) private var dismiss
	@Binding var design: ProfileFontDesign
	@Binding var weight: ProfileFontWeight

	var body: some View {
		NavigationStack {
			Form {
				Section("Design") {
					ForEach(ProfileFontDesign.allCases) { candidate in
						Button(candidate.title, systemImage: design == candidate ? "checkmark.circle.fill" : "circle") {
							design = candidate
						}
						.font(.system(.body, design: candidate.swiftUIFontDesign))
					}
				}

				Section("Weight") {
					Picker("Weight", selection: $weight) {
						ForEach(ProfileFontWeight.allCases) { candidate in
							Text(candidate.title)
								.fontWeight(candidate.swiftUIFontWeight)
								.tag(candidate)
						}
					}
					.pickerStyle(.palette)
				}
			}
			.appNavigationTitle("Profile Font", accent: true)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done", systemImage: "checkmark", role: .confirm, action: dismiss.callAsFunction)
						.buttonStyle(.glassProminent)
				}
			}
		}
	}
}

private extension ProfileFontDesign {
	var title: String {
		rawValue.capitalized
	}
}

private extension ProfileFontWeight {
	var title: String {
		rawValue.capitalized
	}
}
