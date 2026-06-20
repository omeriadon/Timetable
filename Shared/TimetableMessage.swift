//
//  TimetableMessage.swift
//  Shared
//
//  Created by Adon Omeri on 29/4/2026.
//

import Foundation

struct TimetableMessage: Codable {
	let timetable: [Subject]
	let sender: String
	let timestamp: Date

	enum CodingKeys: String, CodingKey {
		case timetable
		case sender
		case timestamp
	}
}

extension TimetableMessage {
	static func encode(_ timetable: [Subject], sender: String = "Unknown") throws -> Data {
		let message = TimetableMessage(
			timetable: timetable,
			sender: sender,
			timestamp: Date()
		)
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return try encoder.encode(message)
	}

	static func decode(_ data: Data) throws -> TimetableMessage {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return try decoder.decode(TimetableMessage.self, from: data)
	}
}
