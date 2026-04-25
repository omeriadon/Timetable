//
//  RGBAColor.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

struct RGBAColor: Codable, Hashable, Defaults.Serializable {
	var r: Double
	var g: Double
	var b: Double
	var a: Double

	var swiftUIColor: Color {
		Color(red: r, green: g, blue: b, opacity: a)
	}

	init(color: Color) {
		let ui = UIColor(color)

		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0

		ui.getRed(&r, green: &g, blue: &b, alpha: &a)

		self.r = Double(r)
		self.g = Double(g)
		self.b = Double(b)
		self.a = Double(a)
	}
}

extension Color {
	func toRGBA() -> RGBAColor {
		RGBAColor(color: self)
	}
}
