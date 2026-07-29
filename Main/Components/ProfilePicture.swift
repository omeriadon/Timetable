import SwiftUI

struct ProfilePicture: View {
	let appearance: ProfileAppearance
	let size: CGFloat
	let badges: [ProfileBadge]
	let accessibilityName: String

	init(
		appearance: ProfileAppearance,
		size: CGFloat,
		badges: [ProfileBadge] = [],
		accessibilityName: String
	) {
		self.appearance = appearance
		self.size = size
		self.badges = badges
		self.accessibilityName = accessibilityName
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
			LinearGradient(
				colors: appearance.colours.map(\.swiftUIColor),
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			if appearance.usesMonogram, !appearance.monogram.isEmpty {
				Text(appearance.monogram)
					.font(.system(size: size * 0.38, weight: .bold, design: fontDesign))
					.foregroundStyle(.white)
			} else {
				Image(systemName: appearance.symbol)
					.font(.system(size: size * 0.38, weight: .semibold))
					.foregroundStyle(.white)
			}
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

	private var fontDesign: Font.Design {
		switch appearance.font {
			case "serif":
				return .serif
			case "monospaced":
				return .monospaced
			case "rounded":
				return .rounded
			default:
				return .default
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
