#if os(iOS)
	import PhotosUI
	import SwiftUI

	struct ProfilePhotoControls: View {
		@Binding var selection: PhotosPickerItem?
		let state: ProfilePhotoSelectionState
		let hasCurrentPhoto: Bool
		let remove: () -> Void

		var body: some View {
			VStack(spacing: 25) {
				PhotosPicker(selection: $selection, matching: .images) {
					Label(hasCurrentPhoto ? "Replace Photo" : "Choose Photo", systemImage: "photo.on.rectangle")
				}
				.buttonStyle(.glass)
				.buttonSizing(.flexible)

				if hasCurrentPhoto {
					Button("Remove Photo", systemImage: "trash", role: .destructive, action: remove)
						.buttonStyle(.glass)
				}

				switch state {
					case .loading:
						ProgressView("Preparing photo…")
					case let .failed(message):
						Label(message, systemImage: "exclamationmark.triangle")
							.foregroundStyle(.red)
					case .idle, .ready:
						EmptyView()
				}
			}
			.padding(.bottom, 10)
			.padding(.horizontal, 8)
		}
	}
#endif
