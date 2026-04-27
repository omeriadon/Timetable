//
//  InlineColorPicker.swift
//  PMS Timetable
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
@available(iOS 15.0, macOS 12, tvOS 16.0, watchOS 8.0, visionOS 1.0, *)
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
		self.systemImage = nil
		self.description = nil
		self.colors = Self.getColors(from: selectedColor.wrappedValue)
	}

	/// Creates an inline color picker with a leading system image.
	/// - Parameters:
	///   - selectedColor: A binding to a `ColorOptions` value.
	///   - systemImage: An SF Symbol name to display next to the picker.
	public init(selectedColor: Binding<T>, systemImage: String) {
		self.selectedColor = selectedColor
		self.systemImage = systemImage
		self.description = nil
		self.colors = Self.getColors(from: selectedColor.wrappedValue)
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
		self.colors = Self.getColors(from: selectedColor.wrappedValue)
	}

	/// Builds the array of available colors from the type of the wrapped value.
	private static func getColors(from colorOptions: T) -> [T] {
		let enumType: any ColorOptions.Type = type(of: colorOptions)
		return Array(enumType.allCases.compactMap { $0 as? T })
	}

	let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

	public var body: some View {
		let pickerBody = ZStack {
			LazyVGrid(columns: columns, spacing: 8) {
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
									isSelected ? .white : .clear,
									lineWidth: 3
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

/// A default type, which can be used to bind the selected color for an ``InlineColorPicker``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public enum AvailableColors: Int, ColorOptions, Codable, Sendable {
	case blue = 0
	case cyan = 1
	case mint = 2
	case green = 3
	case yellow = 4
	case orange = 5
	case red = 6
	case purple = 7
	case indigo = 8

	/// Returns the `Color` for an variable of type ``AvailableColors``.
	public var SwiftUIColor: Color {
		switch self {
		case .blue: return .blue
		case .cyan: return .cyan
		case .mint: return .mint
		case .green: return .green
		case .yellow: return .yellow
		case .orange: return .orange
		case .red: return .red
		case .purple: return .purple
		case .indigo: return .indigo
		}
	}

	/// Returns a description of the color used for accessibility.
	public var accessibilityLabelColorName: String {
		SwiftUIColor.description
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}

// Use this to implement you own collection of colors for the ``InlineColorPicker``.
//
// An Enum conforming to this protocol works best:
//  - Create a new enum and make if conform to ``ColorOptions`` (see an example below).
//  - Create a `@State` variable of you new type.
//  - Bind it to the ``InlineColorPicker`` and your picker will display only your selected Colors
//  - You can also use ``AvailableColors`` which also conforms to this protocol to use the default colors.
// ```swift
// public enum WarmColors: Int, ColorOptions {
//    case yellow = 1
//    case orange = 2
//    case red = 3
//
//    public var SwiftUIColor: Color {
//        switch self {
//        case .yellow:
//            return .yellow
//        case .orange:
//            return .orange
//        case .red:
//            return .red
//        }
//    }
//
//	   public var accessibilityLabelColorName: String {
//         self.SwiftUIColor.description
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.rawValue)
//    }
// }
// ```

public protocol ColorOptions: CaseIterable, Hashable {
	var SwiftUIColor: Color { get }
	var accessibilityLabelColorName: String { get }
}
