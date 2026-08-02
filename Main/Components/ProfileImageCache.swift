import Foundation
import ImageIO

@MainActor
final class ProfileImageCache {
	static let shared = ProfileImageCache()

	private let networkManager = NetworkManager.shared
	private let memoryCache = NSCache<NSString, NSData>()

	private init() {
		memoryCache.totalCostLimit = 12 * 1024 * 1024
		memoryCache.countLimit = 128
	}

	func imageData(for metadata: ProfilePhotoMetadata, displaySize _: Double) async -> Data? {
		let key = cacheKey(for: metadata)
		if let data = memoryCache.object(forKey: key as NSString) {
			return data as Data
		}
		if let data = try? Data(contentsOf: cacheURL(for: key)) {
			memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
			return data
		}

		guard let endpoint = endpoint(for: metadata.url),
		      let original = try? await networkManager.download(endpoint),
		      let downsampled = await Self.downsample(original, maximumPixelSize: 256)
		else {
			return nil
		}

		memoryCache.setObject(downsampled as NSData, forKey: key as NSString, cost: downsampled.count)
		try? FileManager.default.createDirectory(
			at: cacheDirectory,
			withIntermediateDirectories: true
		)
		try? downsampled.write(to: cacheURL(for: key), options: .atomic)
		return downsampled
	}

	private func endpoint(for url: URL) -> Endpoint? {
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			return nil
		}
		let path = components.path.hasPrefix("/api/")
			? String(components.path.dropFirst("/api".count))
			: components.path
		let queryItems = components.queryItems ?? []
		components.queryItems = nil
		return Endpoint(path, queryItems: queryItems)
	}

	private func cacheKey(for metadata: ProfilePhotoMetadata) -> String {
		"\(metadata.checksum)-\(metadata.revision)"
	}

	private var cacheDirectory: URL {
		let base = FileManager.default.containerURL(
			forSecurityApplicationGroupIdentifier: SharedDefaultsStore.suiteName
		) ?? URL.cachesDirectory
		return base.appending(path: "ProfileImages", directoryHint: .isDirectory)
	}

	private func cacheURL(for key: String) -> URL {
		cacheDirectory.appending(path: "\(key).jpg")
	}

	private nonisolated static func downsample(_ data: Data, maximumPixelSize: Int) async -> Data? {
		await Task.detached(priority: .utility) {
			let options: [CFString: Any] = [
				kCGImageSourceCreateThumbnailFromImageAlways: true,
				kCGImageSourceShouldCacheImmediately: true,
				kCGImageSourceCreateThumbnailWithTransform: true,
				kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
			]
			guard let source = CGImageSourceCreateWithData(data as CFData, nil),
			      let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
			else {
				return nil
			}
			let mutableData = NSMutableData()
			guard let destination = CGImageDestinationCreateWithData(
				mutableData,
				"public.jpeg" as CFString,
				1,
				nil
			) else {
				return nil
			}
			CGImageDestinationAddImage(
				destination,
				image,
				[kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary
			)
			guard CGImageDestinationFinalize(destination) else {
				return nil
			}
			return mutableData as Data
		}.value
	}
}
