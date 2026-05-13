//
//  PMS_TimetableApp.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Foundation
import SwiftUI

struct ImportResult: Equatable {
	let success: Bool
	let message: String
}

@main
struct PMS_TimetableApp: App {
	@State private var importedFileURL: URL?
	@State private var importStatus: ImportResult?
	@State private var receivedTimetableData: ShareableTimetableData?

	var body: some Scene {
		WindowGroup {
			ContentView()
				.preferredColorScheme(.dark)
				.onOpenURL { url in
					handleIncomingURL(url)
				}
				.environment(\.importedFileURL, $importedFileURL)
				.environment(\.importStatus, $importStatus)
				.environment(\.receivedTimetableData, $receivedTimetableData)
		}
	}

	private func handleIncomingURL(_ url: URL) {
		if url.isFileURL {
			importedFileURL = url
			return
		}

		guard url.scheme == "pmstimetable" else { return }

		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		let dataParam = components?.fragment ?? components?.queryItems?.first(where: { $0.name == "data" })?.value
		guard let dataParam else {
			return
		}

		do {
			receivedTimetableData = try ShareableTimetableData.fromBase64URL(dataParam)
		} catch {
			print("Failed to decode timetable data: \(error)")
		}
	}
}

struct ImportedFileURLKey: EnvironmentKey {
	static let defaultValue: Binding<URL?> = .constant(nil)
}

struct ImportStatusKey: EnvironmentKey {
	static let defaultValue: Binding<ImportResult?> = .constant(nil)
}

struct ReceivedTimetableDataKey: EnvironmentKey {
	static let defaultValue: Binding<ShareableTimetableData?> = .constant(nil)
}

extension EnvironmentValues {
	var importedFileURL: Binding<URL?> {
		get { self[ImportedFileURLKey.self] }
		set { self[ImportedFileURLKey.self] = newValue }
	}

	var importStatus: Binding<ImportResult?> {
		get { self[ImportStatusKey.self] }
		set { self[ImportStatusKey.self] = newValue }
	}

	var receivedTimetableData: Binding<ShareableTimetableData?> {
		get { self[ReceivedTimetableDataKey.self] }
		set { self[ReceivedTimetableDataKey.self] = newValue }
	}
}
