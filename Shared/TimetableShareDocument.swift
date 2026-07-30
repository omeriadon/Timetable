import Foundation
#if !os(watchOS)
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
	static let timetableShare = UTType(exportedAs: "pt.adonis.timetable.share")
}

struct TimetableShareDocument: FileDocument {
	static let currentFormatVersion = 1
	static var readableContentTypes: [UTType] {
		[.timetableShare]
	}

	let formatVersion: Int
	let locator: String

	init(locator: String) {
		formatVersion = Self.currentFormatVersion
		self.locator = locator
	}

	init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents else {
			throw TimetableShareDocumentError.missingContents
		}
		try self.init(data: data)
	}

	func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
		let data = try JSONEncoder().encode(ExportPayload(
			formatVersion: formatVersion,
			locator: locator
		))
		return FileWrapper(regularFileWithContents: data)
	}

	static func read(from url: URL) throws -> TimetableShareDocument {
		try TimetableShareDocument(data: Data(contentsOf: url))
	}

	private init(data: Data) throws {
		let payload = try JSONDecoder().decode(ExportPayload.self, from: data)
		guard payload.formatVersion == Self.currentFormatVersion else {
			throw TimetableShareDocumentError.unsupportedVersion(payload.formatVersion)
		}
		guard !payload.locator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			throw TimetableShareDocumentError.missingLocator
		}
		formatVersion = payload.formatVersion
		locator = payload.locator
	}

	private struct ExportPayload: Codable {
		let formatVersion: Int
		let locator: String
	}
}

enum TimetableShareDocumentError: LocalizedError {
	case missingContents
	case missingLocator
	case unsupportedVersion(Int)

	var errorDescription: String? {
		switch self {
			case .missingContents:
				"This timetable file has no contents."
			case .missingLocator:
				"This timetable file does not identify a shared timetable."
			case let .unsupportedVersion(version):
				"This timetable file uses unsupported format version \(version)."
		}
	}
}
#endif
