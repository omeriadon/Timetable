//
//  TimetableFileHandler.swift
//  PMS Timetable Message Extension
//
//  Created by Adon Omeri on 29/4/2026.
//

import Foundation
import Defaults

struct TimetableFileHandler {
	static func handleTimetableFile(at fileURL: URL) -> (success: Bool, message: String) {
		do {
			let data = try Data(contentsOf: fileURL)
			let importedMessage = try TimetableMessage.decode(data)

			let importedClasses = importedMessage.timetable
			if importedClasses.isEmpty {
				let result = (false, "No classes in imported timetable")
				return result
			}

			Defaults[.timetable] = importedClasses

			let timestamp = DateFormatter.localizedString(
				from: importedMessage.timestamp,
				dateStyle: .short,
				timeStyle: .short
			)
			let result = (true, "Timetable from \(importedMessage.sender) imported at \(timestamp)")
			return result
		} catch {
			return (false, "Failed to import timetable: \(error.localizedDescription)")
		}
	}
}
