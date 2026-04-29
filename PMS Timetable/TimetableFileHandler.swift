//
//  TimetableFileHandler.swift
//  PMS Timetable
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
				postNotification(result)
				return result
			}

			Defaults[.timetable] = importedClasses

			let timestamp = DateFormatter.localizedString(
				from: importedMessage.timestamp,
				dateStyle: .short,
				timeStyle: .short
			)
			let result = (true, "Timetable from \(importedMessage.sender) imported at \(timestamp)")
			postNotification(result)
			return result
		} catch {
			let result = (false, "Failed to import timetable: \(error.localizedDescription)")
			postNotification(result)
			return result
		}
	}

	private static func postNotification(_ result: (success: Bool, message: String)) {
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				name: NSNotification.Name("TimetableImported"),
				object: nil,
				userInfo: [
					"success": result.success,
					"message": result.message
				]
			)
		}
	}
}
