//
//   DEBUG.swift
//   Shared
//
//   Created by Adon Omeri on 24/6/2026.
//

import Foundation

let debugTimetable: [Subject] = [
	Subject(id: "Maths", symbol: "apple", colour: .init(red: 1, green: 0, blue: 1, alpha: 1), slots: [
		Slot(1, 2),
		Slot(2, 4),
		Slot(4, 5),
	]),
]

let debugSubject = debugTimetable.first!
