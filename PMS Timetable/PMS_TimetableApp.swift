//
//  PMS_TimetableApp.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI

@main
struct PMS_TimetableApp: App {
	@State private var importedFileURL: URL?
	@State private var importStatus: (success: Bool, message: String)?

	var body: some Scene {
		WindowGroup {
			ContentView()
				.preferredColorScheme(.dark)
				.onOpenURL { url in
					handleIncomingFile(url)
				}
				.environment(\.importedFileURL, $importedFileURL)
				.environment(\.importStatus, $importStatus)
		}
	}

	private func handleIncomingFile(_ url: URL) {
		if url.pathExtension == "timetable" {
			let result = TimetableFileHandler.handleTimetableFile(at: url)
			importStatus = result
			try? FileManager.default.removeItem(at: url)
		}
	}
}

struct ImportedFileURLKey: EnvironmentKey {
	static let defaultValue: Binding<URL?> = .constant(nil)
}

struct ImportStatusKey: EnvironmentKey {
	static let defaultValue: Binding<(success: Bool, message: String)?> = .constant(nil)
}

extension EnvironmentValues {
	var importedFileURL: Binding<URL?> {
		get { self[ImportedFileURLKey.self] }
		set { self[ImportedFileURLKey.self] = newValue }
	}

	var importStatus: Binding<(success: Bool, message: String)?> {
		get { self[ImportStatusKey.self] }
		set { self[ImportStatusKey.self] = newValue }
	}
}
