import ColorfulX
import SwiftUI

struct ProfilePicture: View {
	let appearance: ProfileAppearance
	let photo: ProfilePhotoMetadata?
	let size: CGFloat
	let badges: [ProfileBadge]
	let accessibilityName: String
	let animatesBackground: Bool

	init(
		appearance: ProfileAppearance,
		photo: ProfilePhotoMetadata? = nil,
		size: CGFloat,
		badges: [ProfileBadge] = [],
		accessibilityName: String,
		animatesBackground: Bool = false
	) {
		self.appearance = appearance
		self.photo = photo
		self.size = size
		self.badges = badges
		self.accessibilityName = accessibilityName
		self.animatesBackground = animatesBackground
	}

	var body: some View {
		avatarContent
			.frame(width: size, height: size)
			.clipShape(Circle())
			.overlay(alignment: .bottomTrailing) {
				badgeStack
			}
			.accessibilityElement(children: .ignore)
			.accessibilityLabel(accessibilityName)
			.accessibilityValue(badgeAccessibilityValue)
	}

	private var avatarContent: some View {
		ZStack {
			profileBackground

			switch appearance.contentKind {
				case .photo:
					if let photo {
						CachedProfilePhoto(metadata: photo, size: size)
					} else {
						ProfilePhotoPlaceholder(isLoading: false)
					}
				case .monogram:
					Text(appearance.monogram)
						.font(
							.system(
								size: size * 0.38,
								weight: appearance.fontWeight.swiftUIFontWeight,
								design: appearance.fontDesign.swiftUIFontDesign
							)
						)
						.foregroundStyle(.white)
				case .emoji:
					Text(appearance.emoji)
						.font(.system(size: size * 0.42))
			}
		}
	}

	@ViewBuilder
	private var profileBackground: some View {
		if animatesBackground, appearance.contentKind != .photo {
			ColorfulView(
				color: .constant(appearance.colours.map(\.swiftUIColor)),
				speed: .constant(appearance.speed),
				bias: .constant(0.00001),
				noise: .constant(appearance.noise),
				transitionSpeed: .constant(4),
				frameLimit: .constant(30),
				renderScale: .constant(0.75)
			)
		} else {
			LinearGradient(
				colors: appearance.colours.map(\.swiftUIColor),
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		}
	}

	@ViewBuilder
	private var badgeStack: some View {
		let visibleBadges = badges
			.sorted { $0.priority > $1.priority }
			.prefix(3)
		let badgeSize = size * 0.30

		if !visibleBadges.isEmpty {
			HStack(spacing: -(badgeSize * 0.28)) {
				ForEach(Array(visibleBadges.reversed())) { badge in
					Image(systemName: badge.symbol)
						.font(.system(size: badgeSize * 0.52, weight: .bold))
						.foregroundStyle(badge.symbolColor?.swiftUIColor ?? .white)
						.frame(width: badgeSize, height: badgeSize)
						.background(badge.backgroundColor?.swiftUIColor ?? .black, in: Circle())
						.overlay {
							Circle()
								.stroke(.white.opacity(0.85), lineWidth: max(1, size * 0.025))
						}
						.zIndex(Double(badge.priority))
						.accessibilityLabel(badge.accessibilityLabel)
				}
			}
		}
	}

	private var badgeAccessibilityValue: String? {
		let labels = badges
			.sorted { $0.priority > $1.priority }
			.prefix(3)
			.map(\.accessibilityLabel)
		return labels.isEmpty ? nil : labels.joined(separator: ", ")
	}
}

private extension ProfileFontDesign {
	var swiftUIFontDesign: Font.Design {
		switch self {
			case .default:
				.default
			case .serif:
				.serif
			case .monospaced:
				.monospaced
			case .rounded:
				.rounded
		}
	}
}

private extension ProfileFontWeight {
	var swiftUIFontWeight: Font.Weight {
		switch self {
			case .regular:
				.regular
			case .medium:
				.medium
			case .semibold:
				.semibold
			case .bold:
				.bold
			case .heavy:
				.heavy
		}
	}
}
