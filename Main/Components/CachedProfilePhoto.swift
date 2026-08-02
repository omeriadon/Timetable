import SwiftUI

struct CachedProfilePhoto: View {
	let metadata: ProfilePhotoMetadata
	let size: Double
	@State private var data: Data?
	@State private var finishedLoading = false

	var body: some View {
		Group {
			if let data {
				#if os(iOS) || os(watchOS)
					if let image = UIImage(data: data) {
						Image(uiImage: image)
							.resizable()
							.scaledToFill()
					} else {
						ProfilePhotoPlaceholder(isLoading: false)
					}
				#else
					if let image = NSImage(data: data) {
						Image(nsImage: image)
							.resizable()
							.scaledToFill()
					} else {
						ProfilePhotoPlaceholder(isLoading: false)
					}
				#endif
			} else {
				ProfilePhotoPlaceholder(isLoading: !finishedLoading)
			}
		}
		.task(id: metadata) {
			data = await ProfileImageCache.shared.imageData(for: metadata, displaySize: size)
			finishedLoading = true
		}
	}
}
