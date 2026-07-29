import Foundation

nonisolated struct ProfilePhotoMetadata: Codable, Hashable, Sendable {
	let revision: Int
	let url: URL
	let contentType: String
	let byteSize: Int
	let width: Int
	let height: Int
	let checksum: String
	let updatedAt: Date
}
