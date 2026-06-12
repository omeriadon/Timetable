//
//  InlineColorPicker.swift
//  Timetable
//
//  Created by Adon Omeri on 26/4/2026.
//

import SwiftUI

/// An  awesome, simple but customisable Inline color picker. Supports saving a color with `@AppStorage`.  You can provide your own colors by implementing a type conforming to ``ColorOptions``.
///
/// ## How to Use
/// Get started by defining a `@State` variable to hold you selected color.
/// This can either be an on of the enum ``AvailableColors`` or your own implemented color selection conforming to the ``ColorOptions`` protocol:
/// ```swift
/// @State private var myColor: AvailableColors = .blue
/// ```
/// If you want to persist the state over app restarts (e.g. for tint/accentColors), use `@AppStorage`:
/// ```swift
/// @AppStorage("myColor") private var myColor: AvailableColors = .blue
/// ```
/// Add the piker to your `View` and bind you defined variable to it:
/// ```swift
/// InlineColorPicker(selectedColor: $myColor)
/// ```
/// The picker looks best, if you make it a child of a `Form` or `List`
///
/// ### Using the selected Color
/// To use the selected, use the ``ColorOptions/SwiftUIColor`` property:
/// ```swift
///  MyView()
///     .tint(myColor.SwiftUIColor)
/// ```
///
/// ## Styles & Customization
///
/// ### Default Inline Appearance
/// The default initializer creates a compact, inline picker without additional labels or icons:
/// This variant works well inside Form and List rows where minimal visual weight is preferred.
///  ```swift
/// Form {
/// 	InlineColorPicker(selectedColor: $myColor)
/// }
/// ```
/// Results in:
/// ![Default InlineColorPicker](InlineColorPicker)
///
/// ### Inline Picker with Icon
/// To add a leading SF Symbol next to the picker, use the initializer with a systemImage.
/// This is useful when the picker is part of a settings list and should be visually associated with a concept.
/// ```swift
/// Form {
/// 	InlineColorPicker(selectedColor: $myColor, systemImage: "paintbrush")
/// }
/// ```
/// Results in:
/// ![Default InlineColorPicker](InlineColorPickerIcon)
///
/// ### Expanded Picker with Description and Icon
/// For a more expressive layout, use the initializer that includes both a description and an icon.
/// This creates an expanded layout with a header-style label above the picker.
/// This variant is ideal for primary customization options, such as accent or theme colors.
/// ```swift
/// Form {
/// 	InlineColorPicker(
///			selectedColor: $myColor,
///			description: "Accent Color:",
///			systemImage: "paintbrush"
///		)
/// }
/// ```
/// Results in:
/// ![Default InlineColorPicker](InlineColorPickerDescriptionIcon)
public struct InlineColorPicker<T: ColorOptions>: View {
	private let selectedColor: Binding<T>
	private let systemImage: String?
	private let description: LocalizedStringKey?
	private let colors: [T]

	@Namespace private var colorPickerNamespace

	/// Creates an inline color picker with default appearance.
	/// - Parameter selectedColor: A binding to a `ColorOptions` value.
	public init(selectedColor: Binding<T>) {
		self.selectedColor = selectedColor
		systemImage = nil
		description = nil
		colors = Self.getColors(from: selectedColor.wrappedValue)
	}

	/// Creates an inline color picker with a leading system image.
	/// - Parameters:
	///   - selectedColor: A binding to a `ColorOptions` value.
	///   - systemImage: An SF Symbol name to display next to the picker.
	public init(selectedColor: Binding<T>, systemImage: String) {
		self.selectedColor = selectedColor
		self.systemImage = systemImage
		description = nil
		colors = Self.getColors(from: selectedColor.wrappedValue)
	}

	/// Creates an expanded inline color picker with a description and icon.
	/// - Parameters:
	///   - selectedColor: A binding to a `ColorOptions` value.
	///   - description: A localized description shown above the picker.
	///   - systemImage: An SF Symbol name to display next to the description.
	public init(selectedColor: Binding<T>, description: LocalizedStringKey, systemImage: String) {
		self.selectedColor = selectedColor
		self.systemImage = systemImage
		self.description = description
		colors = Self.getColors(from: selectedColor.wrappedValue)
	}

	/// Builds the array of available colors from the type of the wrapped value.
	private static func getColors(from colorOptions: T) -> [T] {
		let enumType: any ColorOptions.Type = type(of: colorOptions)
		return Array(enumType.allCases.compactMap { $0 as? T })
	}

	let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

	public var body: some View {
		let pickerBody = ZStack {
			LazyVGrid(columns: columns, spacing: 4) {
				ForEach(colors.indices, id: \.self) { colorIndex in
					let color = colors[colorIndex]
					let isSelected = (color == selectedColor.wrappedValue)

					Button {
						selectedColor.wrappedValue = color
					} label: {
						if color.SwiftUIColor == .primary {
							Image(systemName: "circle.righthalf.fill")
						} else {
							Circle()
								.fill(color.SwiftUIColor)
								.stroke(
									.white,
									lineWidth: isSelected ? 3 : 0
								)
								.frame(width: 28, height: 28)
						}
					}
					.frame(width: 44, height: 44)
					.buttonStyle(.plain)
				}
			}
		}

		if let description, let systemImage {
			VStack {
				HStack {
					Label(description, systemImage: systemImage)
					Spacer()
					Text(selectedColor.wrappedValue.SwiftUIColor.description.capitalized)
						.foregroundColor(selectedColor.wrappedValue.SwiftUIColor)
				}
				pickerBody
			}
		}

		if let systemImage, description == nil {
			Label {
				pickerBody
			} icon: {
				Image(systemName: systemImage)
					.accessibilityHidden(true)
			}
		}

		if systemImage == nil, description == nil {
			pickerBody
		}
	}

	private func accessibilityName(for color: T) -> String {
		let numColors = colors.count
		let index = colors.firstIndex(of: color) ?? 0
		let name = color.accessibilityLabelColorName

		return String(localized: "Color: \(name) \(index + 1) of \(numColors)")
	}

	private func elementAt<U: Collection>(from collection: U, index: U.Index) -> U.Element? {
		guard collection.indices.contains(index) else {
			return nil
		}
		return collection[index]
	}
}

public enum AvailableColors: Int, ColorOptions, Codable, Sendable {
	case crimsonFlame = 0
	case tangerinePulse = 1
	case solarGold = 2
	case acidLime = 3
	case emeraldDepth = 4
	case aquaSurge = 5
	case electricCyan = 6
	case sapphireVoid = 7
	case royalIndigo = 8
	case neonViolet = 9
	case magentaShock = 10
	case hotFuchsia = 11
	case coralEmber = 12
	case steelBlueGrey = 13
	case obsidianBlack = 14

	/// Returns the `Color` for an variable of type ``AvailableColors``.
	public var SwiftUIColor: Color {
		switch self {
			case .crimsonFlame:
				Color(red: 0.88, green: 0.02, blue: 0.00)

			case .tangerinePulse:
				Color(red: 1.00, green: 0.42, blue: 0.00)

			case .solarGold:
				Color(red: 1.00, green: 0.76, blue: 0.00)

			case .acidLime:
				Color(red: 0.71, green: 1.00, blue: 0.00)

			case .emeraldDepth:
				Color(red: 0.00, green: 0.78, blue: 0.32)

			case .aquaSurge:
				Color(red: 0.00, green: 0.90, blue: 1.00)

			case .electricCyan:
				Color(red: 0.00, green: 0.72, blue: 0.83)

			case .sapphireVoid:
				Color(red: 0.16, green: 0.38, blue: 1.00)

			case .royalIndigo:
				Color(red: 0.24, green: 0.00, blue: 1.00)

			case .neonViolet:
				Color(red: 0.56, green: 0.18, blue: 0.89)

			case .magentaShock:
				Color(red: 1.00, green: 0.00, blue: 0.66)

			case .hotFuchsia:
				Color(red: 1.00, green: 0.18, blue: 0.58)

			case .coralEmber:
				Color(red: 1.00, green: 0.30, blue: 0.30)

			case .steelBlueGrey:
				Color(red: 0.38, green: 0.49, blue: 0.53)

			case .obsidianBlack:
				Color(red: 0.04, green: 0.06, blue: 0.08)
		}
	}

	/// Returns a description of the color used for accessibility.
	public var accessibilityLabelColorName: String {
		switch self {
			case .crimsonFlame: "Crimson Flame"
			case .tangerinePulse: "Tangerine Pulse"
			case .solarGold: "Solar Gold"
			case .acidLime: "Acid Lime"
			case .emeraldDepth: "Emerald Depth"
			case .aquaSurge: "Aqua Surge"
			case .electricCyan: "Electric Cyan"
			case .sapphireVoid: "Sapphire Void"
			case .royalIndigo: "Royal Indigo"
			case .neonViolet: "Neon Violet"
			case .magentaShock: "Magenta Shock"
			case .hotFuchsia: "Hot Fuchsia"
			case .coralEmber: "Coral Ember"
			case .steelBlueGrey: "Steel Blue Grey"
			case .obsidianBlack: "Obsidian Black"
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}

public protocol ColorOptions: CaseIterable, Hashable {
	var SwiftUIColor: Color { get }
	var accessibilityLabelColorName: String { get }
}

func closestColor(to color: Color) -> AvailableColors {
#if os(iOS)
	let uiColor = UIColor(color)
#else
	let uiColor = NSColor(color)
#endif

	var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
	uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

	return AvailableColors.allCases.min(by: { lhs, rhs in
		func components(_ c: Color) -> (CGFloat, CGFloat, CGFloat) {
#if os(iOS)
			let ui = UIColor(c)
#else
			let ui = NSColor(c)
#endif
			var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
			ui.getRed(&r, green: &g, blue: &b, alpha: &a)
			return (r, g, b)
		}

		let (lr, lg, lb) = components(lhs.SwiftUIColor)
		let (rr, rg, rb) = components(rhs.SwiftUIColor)

		let dl = pow(lr - r, 2) + pow(lg - g, 2) + pow(lb - b, 2)
		let dr = pow(rr - r, 2) + pow(rg - g, 2) + pow(rb - b, 2)

		return dl < dr
	})!
}
