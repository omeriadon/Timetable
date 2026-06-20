//
//  defaultTimetable.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

let defaultTimetable: [Subject] = [
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
