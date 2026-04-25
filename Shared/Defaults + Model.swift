//
//  Defaults.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
import Defaults

extension Defaults.Keys {
	static let quality = Key<Double>("quality", default: 0.8)
}

// array of class
// class = name + what slots + colour + symbol

struct Class: Codable, Defaults.Serializable, Identifiable {

	var id: String

	var symbol: String

	var colour: Color.Resolved

	var slots: Set<Int>
}
