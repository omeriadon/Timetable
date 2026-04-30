import Foundation
import SwiftUI
import Compression

struct ShareableSlot: Codable {
	let day: Int
	let period: Int
}

struct ShareableClass: Codable {
	let name: String
	let symbol: String
	let color: String
	let slots: [ShareableSlot]
}

struct ShareableTimetableData: Codable {
	let sender: String
	let classes: [ShareableClass]
	
	func toJSON() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	static func fromJSON(_ data: Data) throws -> ShareableTimetableData {
		return try JSONDecoder().decode(ShareableTimetableData.self, from: data)
	}
	
	func toBase64URL() throws -> String {
		let jsonData = try toJSON()
		let payload = try jsonData.compressedLZFSE()
		return "v2." + payload.base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
	
	static func fromBase64URL(_ encoded: String) throws -> ShareableTimetableData {
		let isV2 = encoded.hasPrefix("v2.")
		let raw = isV2 ? String(encoded.dropFirst(3)) : encoded
		var base64 = raw
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
		
		let padCount = (4 - (base64.count % 4)) % 4
		base64 += String(repeating: "=", count: padCount)
		
		guard let data = Data(base64Encoded: base64) else {
			throw NSError(domain: "DecodeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64"])
		}
		let jsonData = isV2 ? try data.decompressedLZFSE() : data
		return try fromJSON(jsonData)
	}
}

private extension Data {
	func compressedLZFSE() throws -> Data {
		try processBuffer(using: COMPRESSION_LZFSE, encode: true, initialCapacity: Swift.max(64, count))
	}

	func decompressedLZFSE() throws -> Data {
		try processBuffer(using: COMPRESSION_LZFSE, encode: false, initialCapacity: Swift.max(1024, count * 4))
	}

	func processBuffer(using algorithm: compression_algorithm, encode: Bool, initialCapacity: Int) throws -> Data {
		try withUnsafeBytes { rawBuffer in
			guard let srcBase = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
				throw NSError(domain: "CompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing source buffer"])
			}

			var destinationSize = initialCapacity
			while destinationSize <= (count * 32 + 1024) {
				var destination = [UInt8](repeating: 0, count: destinationSize)
				let written: Int = destination.withUnsafeMutableBytes { dst in
					guard let dstBase = dst.bindMemory(to: UInt8.self).baseAddress else { return 0 }
					if encode {
						return compression_encode_buffer(dstBase, destinationSize, srcBase, count, nil, algorithm)
					}
					return compression_decode_buffer(dstBase, destinationSize, srcBase, count, nil, algorithm)
				}

				if written > 0 {
					return Data(destination.prefix(written))
				}
				destinationSize *= 2
			}

			throw NSError(domain: "CompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: encode ? "Compression failed" : "Decompression failed"])
		}
	}
}
