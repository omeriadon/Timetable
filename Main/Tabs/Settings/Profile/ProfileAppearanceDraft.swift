import Foundation

struct ProfileAppearanceDraft {
	var displayName: String
	var contentKind: ProfileContentKind
	var monogram: String
	var emoji: String
	var foregroundColour: RGBAColor
	var fontDesign: ProfileFontDesign
	var fontWeight: ProfileFontWeight
	var colours: [RGBAColor]
	var speed: Double
	var noise: Double
	var photo: ProfilePhotoMetadata?
	var pendingPhotoData: Data?
	var removesPhoto = false

	init(profile: AccountProfile?, fallbackAppearance: ProfileAppearance) {
		let appearance = profile?.appearance ?? fallbackAppearance
		displayName = profile?.displayName ?? ""
		contentKind = appearance.contentKind
		monogram = appearance.monogram
		emoji = appearance.emoji
		foregroundColour = appearance.foregroundColour
		fontDesign = appearance.fontDesign
		fontWeight = appearance.fontWeight
		colours = appearance.colours
		speed = appearance.speed
		noise = appearance.noise
		photo = profile?.photo
	}

	var appearance: ProfileAppearance {
		ProfileAppearance(
			contentKind: contentKind,
			monogram: monogram,
			emoji: emoji,
			foregroundColour: foregroundColour,
			fontDesign: fontDesign,
			fontWeight: fontWeight,
			colours: colours,
			speed: speed,
			noise: noise
		)
	}

	var canSave: Bool {
		guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return false
		}
		switch contentKind {
			case .photo:
				return pendingPhotoData != nil || photo != nil
			case .monogram:
				return !monogram.isEmpty
			case .emoji:
				return !emoji.isEmpty
		}
	}
}
