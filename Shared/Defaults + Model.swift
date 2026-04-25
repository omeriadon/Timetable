//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
import Defaults

let defaultTimetable: [Class] = [
	.init(
		id: "Methods",
		symbol: "radicand.squareroot",
		colour: Color.blue.toRGBA(),
		slots: [
			.init(0, 0),
			.init(1, 1),
			.init(2, 6),
			.init(3, 3),
		]
	),
	.init(
		id: "Physics",
		symbol: "atom",
		colour: Color.red.toRGBA(),
		slots: [
			.init(1, 6),
			.init(2, 1),
			.init(3, 4),
			.init(4, 6),
		]
	),
	.init(
		id: "Computer Science",
		symbol: "laptopcomputer",
		colour: Color.mint.toRGBA(),
		slots: [
			.init(0, 3),
			.init(1, 7),
			.init(3, 6),
			.init(4, 1),
		]
	),
	.init(
		id: "English",
		symbol: "textformat.characters",
		colour: Color.purple.toRGBA(),
		slots: [
			.init(0, 1),
			.init(1, 0),
			.init(2, 4),
			.init(4, 3),
		]
	),
	.init(
		id: "Philosophy",
		symbol: "brain",
		colour: Color.brown.toRGBA(),
		slots: [
			.init(0, 4),
			.init(1, 3),
			.init(2, 6),
			.init(3, 3),
		]
	),
	.init(
		id: "Engineering",
		symbol: "building.columns",
		colour: Color.green.toRGBA(),
		slots: [
			.init(0, 6),
			.init(1, 3),
			.init(2, 7),
			.init(4, 1),
		]
	),
	.init(
		id: "Directed Study",
		symbol: "graduationcap",
		colour: Color.orange.toRGBA(),
		slots: [
			.init(0, 7),
			.init(3, 0),
			.init(4, 0),
		]
	),
	.init(
		id: "Advocacy",
		symbol: "person.3",
		colour: Color.yellow.toRGBA(),
		slots: [
			.init(2, 3),
		]
	),
]

extension Defaults.Keys {
	static let timetable = Key<[Class]>("timetable", default: defaultTimetable)
}

// array of class
// class = name + what slots + colour + symbol

struct Class: Hashable, Codable, Defaults.Serializable, Identifiable {

	var id: String

	var symbol: String

	var colour: RGBAColor

	var slots: [Slot]
}

struct Slot: Hashable, Codable, Defaults.Serializable {
	let day: Int
	let session: Int

	init(_ day: Int, _ session: Int) {
		self.day = day
		self.session = session
	}
}
