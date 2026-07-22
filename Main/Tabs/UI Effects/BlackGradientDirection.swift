//
//  BlackGradientDirection.swift
//  Timetable
//
//  Created by Adon Omeri on 22/7/2026.
//

import SwiftUI

enum BlackGradientDirection {
	case clearTopDarkBottom
	case darkTopClearBottom

	var startPoint: UnitPoint {
		switch self {
			case .clearTopDarkBottom, .darkTopClearBottom:
				.top
		}
	}

	var endPoint: UnitPoint {
		switch self {
			case .clearTopDarkBottom, .darkTopClearBottom:
				.bottom
		}
	}

	var isDarkAtStart: Bool {
		switch self {
			case .darkTopClearBottom:
				true

			case .clearTopDarkBottom:
				false
		}
	}
}
