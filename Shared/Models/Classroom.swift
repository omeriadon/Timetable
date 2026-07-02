//
//   Classroom.swift
//   Shared
//

import Foundation

nonisolated enum Classroom: Codable, Hashable {
	case room(building: Building, floor: Floor?, number: Int)
	case unknown(rawLocation: String)

	nonisolated enum Building: String, Codable, Hashable, CaseIterable {
		case mills
		case andrews
		case beasley
		case gardham
		case embletonMusicCentre
		case stokes

		var displayName: String {
			switch self {
				case .mills: "Mills"
				case .andrews: "Andrews"
				case .beasley: "Beasley"
				case .gardham: "Gardham"
				case .embletonMusicCentre: "Embleton Music Centre"
				case .stokes: "Stokes"
			}
		}

		var code: Character {
			switch self {
				case .mills: "M"
				case .andrews: "A"
				case .beasley: "B"
				case .gardham: "G"
				case .embletonMusicCentre: "E"
				case .stokes: "S"
			}
		}

		var hasFloors: Bool {
			switch self {
				case .mills, .andrews, .beasley: true
				case .gardham, .embletonMusicCentre, .stokes: false
			}
		}
	}

	nonisolated enum Floor: String, Codable, Hashable, CaseIterable {
		case upper
		case lower

		var displayName: String {
			rawValue.capitalized
		}

		var code: Character {
			self == .upper ? "U" : "L"
		}
	}

	init(rawLocation: String) {
		let raw = rawLocation.trimmingCharacters(in: .whitespacesAndNewlines)
		let characters = Array(raw.uppercased())

		guard
			let buildingCode = characters.first,
			let building = Self.building(for: buildingCode)
		else {
			self = .unknown(rawLocation: rawLocation)
			return
		}

		let numberStart: Int
		let floor: Floor?
		if building.hasFloors {
			guard characters.count >= 3, let parsedFloor = Self.floor(for: characters[1]) else {
				self = .unknown(rawLocation: rawLocation)
				return
			}
			floor = parsedFloor
			numberStart = 2
		} else {
			floor = nil
			numberStart = 1
		}

		let numberText = String(characters.dropFirst(numberStart))
		guard (1 ... 2).contains(numberText.count), numberText.allSatisfy(\.isNumber), let number = Int(numberText) else {
			self = .unknown(rawLocation: rawLocation)
			return
		}

		self = .room(building: building, floor: floor, number: number)
	}

	var displayName: String {
		switch self {
			case let .room(building, floor, number):
				if let floor {
					"\(building.displayName), \(floor.displayName), \(number)"
				} else {
					"\(building.displayName), \(number)"
				}
			case let .unknown(rawLocation): rawLocation
		}
	}

	var editorValue: String {
		switch self {
			case let .room(building, floor, number):
				"\(building.code)\(floor.map { String($0.code) } ?? "")\(number)"
			case let .unknown(rawLocation): rawLocation
		}
	}

	private static func building(for code: Character) -> Building? {
		switch code {
			case "M": .mills
			case "A": .andrews
			case "B": .beasley
			case "G": .gardham
			case "E": .embletonMusicCentre
			case "S": .stokes
			default: nil
		}
	}

	private static func floor(for code: Character) -> Floor? {
		switch code {
			case "U": .upper
			case "L": .lower
			default: nil
		}
	}
}
