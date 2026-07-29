#if os(iOS)
	import SwiftUI

	struct ProfilePhotoCropEditor: View {
		@Environment(\.dismiss) private var dismiss
		let sourceData: Data
		let completion: (Data) -> Void
		@State private var zoom = 1.0
		@State private var lastZoom = 1.0
		@State private var offset = CGSize.zero
		@State private var lastOffset = CGSize.zero
		@State private var isPreparing = false
		@State private var errorMessage: String?

		private let viewport = 300.0

		var body: some View {
			NavigationStack {
				VStack(spacing: 20) {
					if let image = UIImage(data: sourceData) {
						Image(uiImage: image)
							.resizable()
							.scaledToFill()
							.frame(width: viewport, height: viewport)
							.scaleEffect(zoom)
							.offset(offset)
							.frame(width: viewport, height: viewport)
							.clipShape(.circle)
							.overlay {
								Circle()
									.stroke(.white, lineWidth: 2)
							}
							.gesture(dragGesture.simultaneously(with: magnifyGesture))
							.accessibilityLabel("Profile photo crop preview")
					} else {
						ContentUnavailableView(
							"Photo Unavailable",
							systemImage: "photo.badge.exclamationmark"
						)
					}

					Text("Drag to reposition and pinch to zoom.")
						.foregroundStyle(.secondary)
				}
				.padding()
				.appNavigationTitle("Crop Photo", accent: true)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button(role: .cancel, action: dismiss.callAsFunction)
					}
					ToolbarItem(placement: .confirmationAction) {
						Button("Use Photo", systemImage: "checkmark", role: .confirm, action: finish)
							.buttonStyle(.glassProminent)
							.disabled(isPreparing)
					}
				}
			}
			.alert("Unable to Prepare Photo", isPresented: Binding(
				get: { errorMessage != nil },
				set: { isPresented in
					if !isPresented {
						errorMessage = nil
					}
				}
			)) {
			} message: {
				Text(errorMessage ?? "")
			}
		}

		private var dragGesture: some Gesture {
			DragGesture()
				.onChanged { value in
					offset = clamped(
						CGSize(
							width: lastOffset.width + value.translation.width,
							height: lastOffset.height + value.translation.height
						)
					)
				}
				.onEnded { _ in
					lastOffset = offset
				}
		}

		private var magnifyGesture: some Gesture {
			MagnifyGesture()
				.onChanged { value in
					zoom = max(1, min(4, lastZoom * value.magnification))
					offset = clamped(offset)
				}
				.onEnded { _ in
					lastZoom = zoom
					lastOffset = offset
				}
		}

		private func clamped(_ proposed: CGSize) -> CGSize {
			guard let image = UIImage(data: sourceData) else {
				return .zero
			}
			let baseScale = max(viewport / image.size.width, viewport / image.size.height)
			let renderedWidth = image.size.width * baseScale * zoom
			let renderedHeight = image.size.height * baseScale * zoom
			let maximumX = max(0, (renderedWidth - viewport) / 2)
			let maximumY = max(0, (renderedHeight - viewport) / 2)
			return CGSize(
				width: min(max(proposed.width, -maximumX), maximumX),
				height: min(max(proposed.height, -maximumY), maximumY)
			)
		}

		private func finish() {
			isPreparing = true
			Task {
				defer {
					isPreparing = false
				}
				do {
					let data = try await ProfilePhotoProcessor.crop(
						sourceData: sourceData,
						zoom: zoom,
						offset: offset,
						viewport: viewport
					)
					completion(data)
					dismiss()
				} catch {
					errorMessage = error.localizedDescription
				}
			}
		}
	}
#endif
