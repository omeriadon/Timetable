import Defaults
import Foundation

nonisolated struct ProfileAppearance: Codable, Defaults.Serializable, Hashable, Sendable {
	let version: Int
	let contentKind: ProfileContentKind
	let monogram: String
	let emoji: String
	let foregroundColour: RGBAColor
	let fontDesign: ProfileFontDesign
	let fontWeight: ProfileFontWeight
	let colours: [RGBAColor]
	let speed: Double
	let noise: Double

	static let currentVersion = 3
	private static let defaultForegroundColour = RGBAColor(
		red: 1,
		green: 1,
		blue: 1,
		alpha: 1
	)
	private static let defaultColours = [
		RGBAColor(red: 0.416, green: 0.655, blue: 1, alpha: 1),
		RGBAColor(red: 0.690, green: 0.424, blue: 1, alpha: 1),
		RGBAColor(red: 0.980, green: 0.616, blue: 0.702, alpha: 1),
	]

	static let `default` = ProfileAppearance(
		contentKind: .emoji,
		monogram: "",
		emoji: "👤",
		foregroundColour: defaultForegroundColour,
		fontDesign: .rounded,
		fontWeight: .semibold,
		colours: defaultColours,
		speed: 0.2,
		noise: 64
	)

	init(
		version: Int = currentVersion,
		contentKind: ProfileContentKind,
		monogram: String,
		emoji: String,
		foregroundColour: RGBAColor,
		fontDesign: ProfileFontDesign,
		fontWeight: ProfileFontWeight,
		colours: [RGBAColor],
		speed: Double,
		noise: Double
	) {
		self.version = version
		self.contentKind = contentKind
		self.monogram = monogram
		self.emoji = emoji
		self.foregroundColour = foregroundColour.normalized
		self.fontDesign = fontDesign
		self.fontWeight = fontWeight
		self.colours = Array(colours.prefix(3)).isEmpty ? Self.defaultColours : Array(colours.prefix(3))
		self.speed = speed
		self.noise = noise
	}

	private enum CodingKeys: String, CodingKey {
		case version
		case contentKind
		case monogram
		case emoji
		case foregroundColour
		case fontDesign
		case fontWeight
		case colours
		case speed
		case noise
		case usesMonogram
		case symbol
		case font
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
		monogram = try container.decodeIfPresent(String.self, forKey: .monogram) ?? ""
		foregroundColour = try container.decodeIfPresent(RGBAColor.self, forKey: .foregroundColour)
			?? Self.defaultForegroundColour
		colours = try Array(
			container.decodeIfPresent([RGBAColor].self, forKey: .colours) ?? Self.defaultColours
		).prefix(3).map(\.self)
		speed = try container.decodeIfPresent(Double.self, forKey: .speed) ?? 0.2
		noise = try container.decodeIfPresent(Double.self, forKey: .noise) ?? 64

		if let contentKind = try container.decodeIfPresent(ProfileContentKind.self, forKey: .contentKind) {
			self.contentKind = contentKind
			emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "👤"
			fontDesign = try container.decodeIfPresent(ProfileFontDesign.self, forKey: .fontDesign) ?? .rounded
			fontWeight = try container.decodeIfPresent(ProfileFontWeight.self, forKey: .fontWeight) ?? .semibold
		} else {
			let usesMonogram = try container.decodeIfPresent(Bool.self, forKey: .usesMonogram) ?? false
			let legacySymbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? "person.fill"
			let legacyFont = try container.decodeIfPresent(String.self, forKey: .font) ?? "rounded"
			contentKind = usesMonogram ? .monogram : .emoji
			emoji = Self.legacyEmoji(for: legacySymbol)
			fontDesign = ProfileFontDesign(rawValue: legacyFont) ?? .rounded
			fontWeight = .semibold
		}
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(version, forKey: .version)
		try container.encode(contentKind, forKey: .contentKind)
		try container.encode(monogram, forKey: .monogram)
		try container.encode(emoji, forKey: .emoji)
		try container.encode(foregroundColour, forKey: .foregroundColour)
		try container.encode(fontDesign, forKey: .fontDesign)
		try container.encode(fontWeight, forKey: .fontWeight)
		try container.encode(colours, forKey: .colours)
		try container.encode(speed, forKey: .speed)
		try container.encode(noise, forKey: .noise)
	}

	private static func legacyEmoji(for symbol: String) -> String {
		switch symbol {
			case "star.fill":
				"⭐️"
			case "bolt.fill":
				"⚡️"
			case "book.fill":
				"📚"
			case "figure.run":
				"🏃"
			case "music.note":
				"🎵"
			case "gamecontroller.fill":
				"🎮"
			case "paintpalette.fill":
				"🎨"
			case "paperplane.fill":
				"✈️"
			default:
				"👤"
		}
	}
}
