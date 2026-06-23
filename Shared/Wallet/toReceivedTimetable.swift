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

		// 1. Grab and unpack the root userInfo object
		guard let userInfo = self.userInfo,
		      let rawJsonString = userInfo["rawTimetableData"] as? String,
		      let jsonData = rawJsonString.data(using: .utf8)
		else {
			return nil
		}

		// 2. Safely decode structural subject data
		guard let subjects = try? JSONDecoder().decode([Subject].self, from: jsonData) else {
			return nil
		}

		// 3. Extract sender name strictly from backFields metadata
		// PKPass localizes and exposes these fields directly via localizedValue(forFieldKey:)
		guard let senderName = self.localizedValue(forFieldKey: "sender") as? String,
		      !senderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		else {
			return nil
		}

		// 4. Extract the exact historic sharing timestamp from the pass data fields
		// Since it's stored as an ISO8601 string ("2026-06-22T11:17:52Z") in primaryFields,
		// we extract and convert it back to a standard Date object.
		guard let sharedString = self.localizedValue(forFieldKey: "shared") as? String,
		      let sharedDate = ISO8601DateFormatter().date(from: sharedString)
		else {
			return nil
		}

		// All-or-nothing check passed successfully
		return ReceivedTimetable(
			sender: senderName,
			subjects: subjects,
			receivedAt: sharedDate
		)
	}
}
