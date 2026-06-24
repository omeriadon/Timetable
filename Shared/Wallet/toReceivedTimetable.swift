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
		// Ensure this pass belongs specifically to your Timetable bundle ID identifier
		guard self.passTypeIdentifier == "pass.com.omeriadon.Timetable" else { return nil }

		// 1. Grab the raw userInfo object
		guard let userInfo = self.userInfo else {
			Print("❌ Pass Parsing Error: userInfo dictionary is completely missing.")
			return nil
		}

		// 2. Extract the timetable array payload
		guard let rawData = userInfo["rawTimetableData"] else {
			Print("❌ Pass Parsing Error: 'rawTimetableData' key is missing from userInfo.")
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
				Print("❌ Pass Parsing Error: JSONSerialization failed: \(error)")
				return nil
			}
		}

		// 4. Decode the subject data layout
		guard let subjects = try? JSONDecoder().decode([Subject].self, from: jsonData) else {
			Print("❌ Pass Parsing Error: JSON structure layout does not match your [Subject] model.")
			return nil
		}

		// 5. Extract sender name (Try userInfo first, fallback to back-of-pass fields)
		let senderName: String
		if let userInfoSender = userInfo["sender"] as? String {
			senderName = userInfoSender
		} else if let passFieldSender = self.localizedValue(forFieldKey: "sender") as? String {
			senderName = passFieldSender
		} else {
			Print("❌ Pass Parsing Error: 'sender' identifier not found in userInfo or pass fields.")
			return nil
		}

		guard !senderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

		// 6. Extract sharing timestamp
		let sharedDate: Date

		if let userInfoShared = userInfo["shared"] as? String,
		   let parsedDate = ISO8601DateFormatter().date(from: userInfoShared)
		{
			sharedDate = parsedDate
		} else if let rawShared = self.localizedValue(forFieldKey: "shared") {
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
					Print("⚠️ Pass Parsing Warning: 'shared' text found but formatting failed: \(dateString). Defaulting to current date.")
					sharedDate = Date()
				}
			} else {
				Print("⚠️ Pass Parsing Warning: 'shared' field is an unexpected type. Defaulting to current date.")
				sharedDate = Date()
			}
		} else {
			Print("⚠️ Pass Parsing Warning: 'shared' key not found in userInfo or pass fields. Defaulting to current date.")
			sharedDate = Date()
		}

		var timetable = ReceivedTimetable(
			sender: senderName,
			subjects: subjects,
			receivedAt: sharedDate
		)
		timetable.id = self.serialNumber

		return timetable
	}
}
