import SwiftUI

struct ProfileColourGrid: View {
	@Environment(\.dismiss) private var dismiss
	@Binding var selection: [RGBAColor]

	private static let columnCount = 15

	private let columns = Array(
		repeating: GridItem(.flexible(), spacing: 0),
		count: Self.columnCount
	)

	private let palette = Self.makePalette()

	var body: some View {
		LazyVGrid(columns: columns, spacing: 0) {
			ForEach(palette) { item in
				Button {
					toggle(item.colour)
				} label: {
					Rectangle()
						.fill(item.colour.swiftUIColor)
						.aspectRatio(1, contentMode: .fit)
						.overlay {
							if contains(item.colour) {
								ConcentricRectangle(corners: .concentric(), isUniform: false)
									.stroke(.white, lineWidth: 6)
									.clipShape(ConcentricRectangle(corners: .concentric(), isUniform: false))
									.transition(.blurReplace)
							}
						}
						.animation(.snappy(duration: 0.1), value: contains(item.colour))
				}
				.buttonStyle(.plain)
				.accessibilityValue(
					contains(item.colour) ? "Selected" : "Not selected"
				)
			}
		}
		.compositingGroup()
	}

	private func toggle(_ colour: RGBAColor) {
		if let index = selection.firstIndex(of: colour) {
			guard selection.count > 1 else {
				return
			}

			selection.remove(at: index)
			return
		}

		if selection.count >= 3 {
			selection.remove(at: 0)
		}

		selection.append(colour)
	}

	private func contains(_ colour: RGBAColor) -> Bool {
		selection.contains(colour)
	}

	private static func makePalette() -> [ProfilePaletteColour] {
		let colourRowCount = 12
		let saturation = 0.75

		var rows: [[ProfilePaletteColour]] = (0 ..< colourRowCount).map { row in
			let t = Double(row) / Double(colourRowCount - 1)
			let lightness = 0.92 - t * 0.84

			return (0 ..< columnCount).map { column in
				let hue = Double(column) / Double(columnCount)
				let (r, g, b) = hslToRGB(hue: hue, saturation: saturation, lightness: lightness)
				let colour = RGBAColor(red: r, green: g, blue: b, alpha: 1)
				return ProfilePaletteColour(id: "\(row)-\(column)", colour: colour)
			}
		}

		let greyRow = (0 ..< columnCount).map { column -> ProfilePaletteColour in
			let t = Double(column) / Double(columnCount - 1)
			let lightness = 1 - t
			let colour = RGBAColor(red: lightness, green: lightness, blue: lightness, alpha: 1)
			return ProfilePaletteColour(id: "grey-\(column)", colour: colour)
		}
		rows.append(greyRow)

		return rows.flatMap(\.self)
	}

	private static func hslToRGB(hue: Double, saturation: Double, lightness: Double) -> (Double, Double, Double) {
		if saturation == 0 {
			return (lightness, lightness, lightness)
		}

		let q = lightness < 0.5 ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation
		let p = 2 * lightness - q

		func hueToRGB(_ t: Double) -> Double {
			var t = t
			if t < 0 {
				t += 1
			}
			if t > 1 {
				t -= 1
			}
			if t < 1 / 6 {
				return p + (q - p) * 6 * t
			}
			if t < 1 / 2 {
				return q
			}
			if t < 2 / 3 {
				return p + (q - p) * (2 / 3 - t) * 6
			}
			return p
		}

		return (hueToRGB(hue + 1 / 3), hueToRGB(hue), hueToRGB(hue - 1 / 3))
	}

	private static func rgba(hue: Double, saturation: Double, brightness: Double) -> RGBAColor {
		let sector = hue * 6
		let index = Int(sector.rounded(.down))
		let fraction = sector - Double(index)
		let p = brightness * (1 - saturation)
		let q = brightness * (1 - saturation * fraction)
		let t = brightness * (1 - saturation * (1 - fraction))
		let components = switch index % 6 {
			case 0:
				(brightness, t, p)
			case 1:
				(q, brightness, p)
			case 2:
				(p, brightness, t)
			case 3:
				(p, q, brightness)
			case 4:
				(t, p, brightness)
			default:
				(brightness, p, q)
		}
		return RGBAColor(red: components.0, green: components.1, blue: components.2, alpha: 1)
	}
}
