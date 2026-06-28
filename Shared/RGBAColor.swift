//
//   RGBAColor.swift
//   Shared
//
//   Created by Adon Omeri on 25/4/2026.
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

	init(r: Double, g: Double, b: Double, a: Double) {
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	}

	init(red: Double, green: Double, blue: Double, alpha: Double) {
		r = red
		g = green
		b = blue
		a = alpha
	}

	init(color: Color) {
		#if os(iOS) || os(watchOS)
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

		#else
			let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.white

			var r: CGFloat = 0
			var g: CGFloat = 0
			var b: CGFloat = 0
			var a: CGFloat = 0

			ns.getRed(&r, green: &g, blue: &b, alpha: &a)

			self.r = Double(r)
			self.g = Double(g)
			self.b = Double(b)
			self.a = Double(a)
		#endif
	}

	init(hexString: String) {
		let hex = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		let scanner = Scanner(string: hex)
		var rgb: UInt64 = 0
		scanner.scanHexInt64(&rgb)

		let r = Double((rgb >> 16) & 0xFF) / 255.0
		let g = Double((rgb >> 8) & 0xFF) / 255.0
		let b = Double(rgb & 0xFF) / 255.0

		self.init(r: r, g: g, b: b, a: 1.0)
	}
}

extension Color {
	func toRGBA() -> RGBAColor {
		RGBAColor(color: self)
	}
}
