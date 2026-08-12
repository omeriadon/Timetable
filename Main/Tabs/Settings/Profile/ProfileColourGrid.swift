import SwiftUI

struct ProfileColourGrid: View {
	let close: () -> Void = {}
	@Binding var selection: [RGBAColor]

	static let columnCount = 15

	private let columns = Array(
		repeating: GridItem(.flexible(), spacing: 0),
		count: Self.columnCount
	)

	private let palette = Self.makePalette(
		colourRowCount: 6,
		columnCount: Self.columnCount,
		includesMonochrome: true
	)

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
				.accessibilityLabel(colourAccessibilityLabel(for: item.colour))
				.accessibilityValue(
					contains(item.colour) ? "Selected" : "Not selected"
				)
				.accessibilityAddTraits(contains(item.colour) ? .isSelected : [])
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

	static func makePalette(
		colourRowCount: Int,
		columnCount: Int,
		includesMonochrome: Bool
	) -> [ProfilePaletteColour] {
		let saturation = 0.75

		var rows: [[ProfilePaletteColour]] = (0 ..< colourRowCount).map { row in
			let t = colourRowCount == 1 ? 0.5 : Double(row) / Double(colourRowCount - 1)
			let lightness = 0.92 - t * 0.84

			return (0 ..< columnCount).map { column in
				let hue = Double(column) / Double(columnCount)
				let (r, g, b) = hslToRGB(hue: hue, saturation: saturation, lightness: lightness)
				let colour = RGBAColor(red: r, green: g, blue: b, alpha: 1)
				return ProfilePaletteColour(id: "\(row)-\(column)", colour: colour)
			}
		}

		if includesMonochrome {
			let greyRow = (0 ..< columnCount).map { column -> ProfilePaletteColour in
				let t = Double(column) / Double(columnCount - 1)
				let lightness = 1 - t
				let colour = RGBAColor(red: lightness, green: lightness, blue: lightness, alpha: 1)
				return ProfilePaletteColour(id: "grey-\(column)", colour: colour)
			}
			rows.append(greyRow)
		}

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

struct ProfileForegroundColourGrid: View {
	@Binding var selection: RGBAColor

	private let palette = ProfileColourGrid.makePalette(
		colourRowCount: 2,
		columnCount: ProfileColourGrid.columnCount - 1,
		includesMonochrome: false
	)
	private let monochromeColours = [
		RGBAColor(hexString: "#FFFFFF"),
		RGBAColor(hexString: "#000000"),
	]
	private let columns = Array(
		repeating: GridItem(.flexible(), spacing: 0),
		count: ProfileColourGrid.columnCount - 1
	)

	var body: some View {
		GeometryReader { proxy in
			let swatchSize = proxy.size.width / CGFloat(ProfileColourGrid.columnCount)

			HStack(spacing: 0) {
				LazyVGrid(columns: columns, spacing: 0) {
					ForEach(palette) { item in
						colourButton(item.colour)
					}
				}
				.frame(width: swatchSize * CGFloat(ProfileColourGrid.columnCount - 1))

				VStack(spacing: 0) {
					ForEach(monochromeColours, id: \.self) { colour in
						colourButton(colour)
					}
				}
				.frame(width: swatchSize)
			}
		}
		.aspectRatio(CGFloat(ProfileColourGrid.columnCount) / 2, contentMode: .fit)
		.compositingGroup()
	}

	private func colourButton(_ colour: RGBAColor) -> some View {
		let isSelected = selection == colour

		return Button {
			selection = colour
		} label: {
			Rectangle()
				.fill(colour.swiftUIColor)
				.aspectRatio(1, contentMode: .fit)
				.overlay {
					if isSelected {
						ConcentricRectangle(corners: .concentric(), isUniform: false)
							.stroke(selectionStrokeColour(for: colour), lineWidth: 6)
							.clipShape(ConcentricRectangle(corners: .concentric(), isUniform: false))
					}
				}
		}
		.buttonStyle(.plain)
		.accessibilityLabel(colourAccessibilityLabel(for: colour))
		.accessibilityValue(isSelected ? "Selected" : "Not selected")
		.accessibilityAddTraits(isSelected ? .isSelected : [])
	}

	private func selectionStrokeColour(for colour: RGBAColor) -> Color {
		let luminance = 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
		return luminance > 0.6 ? .black : .white
	}
}

func colourAccessibilityLabel(for colour: RGBAColor) -> String {
	let red = Int((colour.r * 255).rounded())
	let green = Int((colour.g * 255).rounded())
	let blue = Int((colour.b * 255).rounded())
	return "Profile colour, red \(red), green \(green), blue \(blue)"
}
