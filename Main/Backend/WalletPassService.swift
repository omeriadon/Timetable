//
//   WalletPassService.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation
import Observation
import PassKit

@MainActor
@Observable
final class WalletPassService {
	static let shared = WalletPassService(networkManager: .shared)

	private(set) var isDownloading = false

	private let networkManager: NetworkManager

	private var downloadTask: Task<Data, any Error>?

	private init(
		networkManager: NetworkManager
	) {
		self.networkManager = networkManager
	}

	func downloadOwnerPass() async throws -> PKPass {
		let data = try await downloadOwnerPassData()
		return try PKPass(data: data)
	}

	func downloadPass(timetableID: UUID) async throws -> PKPass {
		let data = try await networkManager.download(Endpoint("/v1/timetables/\(timetableID.uuidString)/pass"))
		return try PKPass(data: data)
	}

	func ownerPassFileURL() async throws -> URL {
		let name = if let displayName = Defaults[.accountProfile]?.displayName {
			"\(displayName)'s Timetable"
		} else {
			"Timetable"
		}

		let data = try await downloadOwnerPassData()
		let fileURL = FileManager.default.temporaryDirectory
			.appending(path: "\(name)-\(UUID().uuidString)")
			.appendingPathExtension("pkpass")
		try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
		return fileURL
	}

	func receivedPassFileURL(serialNumber: String) async throws -> URL {
		let encodedSerial = serialNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? serialNumber
		let data = try await networkManager.download(Endpoint("/v1/passes/received/\(encodedSerial)"))
		let fileURL = FileManager.default.temporaryDirectory
			.appending(path: "Shared-Timetable-\(UUID().uuidString)")
			.appendingPathExtension("pkpass")
		try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
		return fileURL
	}

	func passFileURL(timetableID: UUID, name: String) async throws -> URL {
		let data = try await networkManager.download(Endpoint("/v1/timetables/\(timetableID.uuidString)/pass"))
		let fileURL = FileManager.default.temporaryDirectory
			.appending(path: "\(name)-\(UUID().uuidString)")
			.appendingPathExtension("pkpass")
		try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
		return fileURL
	}

	private func downloadOwnerPassData() async throws -> Data {
		if let downloadTask {
			return try await downloadTask.value
		}

		let task = Task { @MainActor in
			try await networkManager.download(.v1OwnerPass)
		}
		downloadTask = task
		isDownloading = true
		defer {
			downloadTask = nil
			isDownloading = false
		}
		return try await task.value
	}
}

private extension Endpoint {
	static let v1OwnerPass = Endpoint("/v1/passes/owner")
}
