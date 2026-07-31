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
								Rectangle()
									.strokeBorder(.white, lineWidth: 3)
									.transition(.opacity)
							}
						}
						.animation(.snappy, value: contains(item.colour))
				}
				.buttonStyle(.plain)
				.accessibilityValue(
					contains(item.colour) ? "Selected" : "Not selected"
				)
			}
		}
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
		(0 ..< 10).flatMap { row in
			(0 ..< Self.columnCount).map { column in
				let hue = Double(column) / Double(Self.columnCount)
				let saturation = 0.35 + (Double(row) * 0.06)
				let brightness = 0.98 - (Double(row) * 0.065)
				let colour = rgba(hue: hue, saturation: min(saturation, 0.95), brightness: max(brightness, 0.32))
				return ProfilePaletteColour(id: "\(row)-\(column)", colour: colour)
			}
		}
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
