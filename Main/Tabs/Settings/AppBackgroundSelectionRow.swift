import SwiftUI

struct AppBackgroundSelectionRow: View {
	let background: AppBackground
	let isSelected: Bool
	let select: () -> Void

	var body: some View {
		Button(action: select) {
			ZStack {
				AppBackgroundSurface(background: background)
					.overlay {
						Color.black.opacity(0.16)
					}

				HStack(spacing: 12) {
					Label(background.title, systemImage: background.symbol)
						.font(.headline)

					Spacer()

					if isSelected {
						Image(systemName: "checkmark.circle.fill")
							.font(.title2)
							.accessibilityLabel("Selected")
					}
				}
				.padding(.horizontal, 16)
			}
			.frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
			.foregroundStyle(.white)
			.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			.contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			.shadow(color: .black.opacity(0.35), radius: 1, y: 1)
		}
		.buttonStyle(.plain)
		.accessibilityValue(isSelected ? "Selected" : "Not selected")
	}
}
