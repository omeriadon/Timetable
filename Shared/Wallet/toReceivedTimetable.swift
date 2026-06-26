//
//  toReceivedTimetable.swift
//  Timetable
//
//  Created by Adon Omeri on 22/6/2026.
//

import Foundation
import PassKit

extension PKPass {
	/// Attempts to extract and transform the pass's internal properties into a `ReceivedTimetable`
	/// Returns `nil` if any required metadata field is missing or unparseable.
	func toReceivedTimetable() -> ReceivedTimetable? {
		if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
			return ReceivedTimetable(sender: "monkey", subjects: [
				Subject(
					id: "mathematics",
					symbol: "function",
					colour: RGBAColor(hexString: "#3B82F6"),
					slots: [Slot(0, 0), Slot(2, 1), Slot(4, 2)]
				),

				Subject(
					id: "english",
					symbol: "book.fill",
					colour: RGBAColor(hexString: "#EF4444"),
					slots: [Slot(1, 0), Slot(3, 2), Slot(4, 4)]
				),

				Subject(
					id: "science",
					symbol: "atom",
					colour: RGBAColor(hexString: "#10B981"),
					slots: [Slot(0, 2), Slot(2, 3), Slot(3, 0)]
				),

				Subject(
					id: "history",
					symbol: "building.columns.fill",
					colour: RGBAColor(hexString: "#F59E0B"),
					slots: [Slot(1, 1), Slot(3, 3)]
				),

				Subject(
					id: "geography",
					symbol: "globe.europe.africa.fill",
					colour: RGBAColor(hexString: "#06B6D4"),
					slots: [Slot(0, 4), Slot(2, 0)]
				),

				Subject(
					id: "physics",
					symbol: "bolt.fill",
					colour: RGBAColor(hexString: "#8B5CF6"),
					slots: [Slot(1, 4), Slot(4, 1)]
				),

				Subject(
					id: "chemistry",
					symbol: "testtube.2",
					colour: RGBAColor(hexString: "#EC4899"),
					slots: [Slot(0, 1), Slot(2, 4)]
				),

				Subject(
					id: "computer-science",
					symbol: "desktopcomputer",
					colour: RGBAColor(hexString: "#64748B"),
					slots: [Slot(1, 3), Slot(3, 1), Slot(4, 0)]
				),

				Subject(
					id: "art",
					symbol: "paintpalette.fill",
					colour: RGBAColor(hexString: "#F97316"),
					slots: [Slot(2, 2), Slot(4, 3)]
				),

				Subject(
					id: "physical-education",
					symbol: "figure.run",
					colour: RGBAColor(hexString: "#22C55E"),
					slots: [Slot(0, 3), Slot(3, 4)]
				),
			],
			receivedAt: Date())
		}

		// Ensure this pass belongs specifically to your Timetable bundle ID identifier
		guard passTypeIdentifier == "pass.com.omeriadon.Timetable" else { return nil }

		// 1. Grab the raw userInfo object
		guard let userInfo else {
			PrintError("❌ Pass Parsing Error: userInfo dictionary is completely missing.")
			return nil
		}

		// 2. Extract the timetable array payload
		guard let rawData = userInfo["rawTimetableData"] else {
			PrintError("❌ Pass Parsing Error: 'rawTimetableData' key is missing from userInfo.")
			return nil
		}

		// 3. Serialize back to raw JSON Data safely
		let jsonData: Data
		if let jsonString = rawData as? String {
			guard let data = jsonString.data(using: .utf8) else { return nil }
			jsonData = data
		} else {
			do {
				jsonData = try JSONSerialization.data(withJSONObject: rawData, options: [])
			} catch {
				PrintError("❌ Pass Parsing Error: JSONSerialization failed: \(error)")
				return nil
			}
		}

		// 4. Decode the subject data layout
		guard let subjects = try? JSONDecoder().decode([Subject].self, from: jsonData) else {
			PrintError("❌ Pass Parsing Error: JSON structure layout does not match your [Subject] model.")
			return nil
		}

		// 5. Extract sender name (Try userInfo first, fallback to back-of-pass fields)
		let senderName: String
		if let userInfoSender = userInfo["sender"] as? String {
			senderName = userInfoSender
		} else if let passFieldSender = localizedValue(forFieldKey: "sender") as? String {
			senderName = passFieldSender
		} else {
			PrintError("❌ Pass Parsing Error: 'sender' identifier not found in userInfo or pass fields.")
			return nil
		}

		guard !senderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

		// 6. Extract sharing timestamp
		let sharedDate: Date

		if let userInfoShared = userInfo["shared"] as? String,
		   let parsedDate = ISO8601DateFormatter().date(from: userInfoShared)
		{
			sharedDate = parsedDate
		} else if let rawShared = localizedValue(forFieldKey: "shared") {
			if let alreadyDate = rawShared as? Date {
				sharedDate = alreadyDate
			} else if let dateString = rawShared as? String {
				let fallbackFormatter = DateFormatter()
				fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
				fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
				fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)

				// If Apple Wallet localized the string, parsing will fail.
				// Fallback to Date() to prevent the whole pass from failing to load.
				if let parsed = ISO8601DateFormatter().date(from: dateString) ?? fallbackFormatter.date(from: dateString) {
					sharedDate = parsed
				} else {
					PrintError("⚠️ Pass Parsing Warning: 'shared' text found but formatting failed: \(dateString). Defaulting to current date.")
					sharedDate = Date()
				}
			} else {
				PrintError("⚠️ Pass Parsing Warning: 'shared' field is an unexpected type. Defaulting to current date.")
				sharedDate = Date()
			}
		} else {
			PrintError("⚠️ Pass Parsing Warning: 'shared' key not found in userInfo or pass fields. Defaulting to current date.")
			sharedDate = Date()
		}

		var timetable = ReceivedTimetable(
			sender: senderName,
			subjects: subjects,
			receivedAt: sharedDate
		)
		timetable.id = serialNumber

		return timetable
	}
}
