import SwiftUI

struct ProfilePhotoPlaceholder: View {
	let isLoading: Bool

	var body: some View {
		ZStack {
			Color.secondary.opacity(0.16)

			if isLoading {
				ProgressView()
					.controlSize(.small)
			} else {
				Image(systemName: "person.crop.circle.fill")
					.resizable()
					.scaledToFit()
					.padding(12)
					.foregroundStyle(.secondary)
					.accessibilityHidden(true)
			}
		}
	}
}
