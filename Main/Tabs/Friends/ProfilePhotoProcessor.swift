#if os(iOS)
	import Foundation
	import ImageIO
	import UIKit

	enum ProfilePhotoProcessor {
		static func prepareSource(_ sourceData: Data) async throws -> Data {
			try await Task.detached(priority: .userInitiated) {
				let options: [CFString: Any] = [
					kCGImageSourceCreateThumbnailFromImageAlways: true,
					kCGImageSourceShouldCacheImmediately: true,
					kCGImageSourceCreateThumbnailWithTransform: true,
					kCGImageSourceThumbnailMaxPixelSize: 2048,
				]
				guard let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
				      let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
				      let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.95)
				else {
					throw ProfilePhotoSelectionError.unreadableImage
				}
				return data
			}.value
		}

		static func crop(
			sourceData: Data,
			zoom: Double,
			offset: CGSize,
			viewport: Double
		) async throws -> Data {
			try await Task.detached(priority: .userInitiated) {
				guard let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
				      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
				else {
					throw ProfilePhotoSelectionError.unreadableImage
				}

				let sourceWidth = Double(image.width)
				let sourceHeight = Double(image.height)
				let baseScale = max(viewport / sourceWidth, viewport / sourceHeight)
				let totalScale = baseScale * max(1, zoom)
				let visibleSide = viewport / totalScale
				let sourceCenterX = sourceWidth / 2 - offset.width / totalScale
				let sourceCenterY = sourceHeight / 2 - offset.height / totalScale
				let cropRect = CGRect(
					x: sourceCenterX - visibleSide / 2,
					y: sourceCenterY - visibleSide / 2,
					width: visibleSide,
					height: visibleSide
				).integral
				guard let cropped = image.cropping(to: cropRect) else {
					throw ProfilePhotoSelectionError.encodingFailed
				}

				guard let colourSpace = CGColorSpace(name: CGColorSpace.sRGB),
				      let context = CGContext(
				      	data: nil,
				      	width: 1024,
				      	height: 1024,
				      	bitsPerComponent: 8,
				      	bytesPerRow: 1024 * 4,
				      	space: colourSpace,
				      	bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
				      )
				else {
					throw ProfilePhotoSelectionError.encodingFailed
				}
				context.interpolationQuality = .high
				context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
				guard let resizedImage = context.makeImage() else {
					throw ProfilePhotoSelectionError.encodingFailed
				}
				let resized = UIImage(cgImage: resizedImage)
				for quality in stride(from: 0.9, through: 0.2, by: -0.1) {
					if let data = resized.jpegData(compressionQuality: quality), data.count <= 1_000_000 {
						return data
					}
				}
				throw ProfilePhotoSelectionError.imageTooLarge
			}.value
		}
	}
#endif
