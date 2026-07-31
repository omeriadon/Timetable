import ColorfulX
import SwiftUI

struct ProfilePicture: View {
	private enum PhotoSource {
		case remote(ProfilePhotoMetadata)
		case local(Image)
	}

	let appearance: ProfileAppearance
	private let photoSource: PhotoSource?
	let size: CGFloat?
	let badges: [ProfileBadge]
	let accessibilityName: String
	let animatesBackground: Bool

	init(
		appearance: ProfileAppearance,
		photo: ProfilePhotoMetadata? = nil,
		size: CGFloat? = nil,
		badges: [ProfileBadge] = [],
		accessibilityName: String,
		animatesBackground: Bool = false
	) {
		self.appearance = appearance
		photoSource = photo.map(PhotoSource.remote)
		self.size = size
		self.badges = badges
		self.accessibilityName = accessibilityName
		self.animatesBackground = animatesBackground
	}

	init(
		appearance: ProfileAppearance,
		localImage: Image,
		size: CGFloat? = nil,
		badges: [ProfileBadge] = [],
		accessibilityName: String,
		animatesBackground: Bool = false
	) {
		self.appearance = appearance
		photoSource = .local(localImage)
		self.size = size
		self.badges = badges
		self.accessibilityName = accessibilityName
		self.animatesBackground = animatesBackground
	}

	var body: some View {
		Group {
			if let size {
				content(size: size)
			} else {
				GeometryReader { proxy in
					let resolved = min(proxy.size.width, proxy.size.height)
					content(size: resolved)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				}
			}
		}
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(accessibilityName)
		.accessibilityValue(badgeAccessibilityValue ?? "")
	}

	private func content(size: CGFloat) -> some View {
		avatarContent(size: size)
			.frame(width: size, height: size)
			.clipShape(Circle())
			.overlay(alignment: .bottomTrailing) {
				badgeStack(size: size)
			}
	}

	private func avatarContent(size: CGFloat) -> some View {
		ZStack {
			profileBackground

			switch appearance.contentKind {
				case .photo:
					switch photoSource {
						case let .remote(metadata):
							CachedProfilePhoto(metadata: metadata, size: size)
						case let .local(image):
							image
								.resizable()
								.scaledToFill()
						case nil:
							ProfilePhotoPlaceholder(isLoading: false)
					}

				case .monogram:
					Text(appearance.monogram)
						.font(
							.system(
								size: 150,
								weight: appearance.fontWeight.profilePictureFontWeight
							)
						)
						.fontDesign(appearance.fontDesign.profilePictureFontDesign)
						.minimumScaleFactor(0.01)
						.foregroundStyle(.white)
						.padding(size * 0.15)
						.contentTransition(.numericText())
						.animation(.easeInOut, value: appearance.fontDesign.profilePictureFontDesign)
						.animation(.easeInOut, value: appearance.fontWeight.profilePictureFontWeight)
						.animation(.easeInOut, value: appearance.monogram)

				case .emoji:
					Text(appearance.emoji)
						.font(.system(size: 150))
						.minimumScaleFactor(0.01)
						.padding(size * 0.15)
			}
		}
	}

	@ViewBuilder
	private var profileBackground: some View {
		if animatesBackground, appearance.contentKind != .photo {
			ColorfulView(
				color: .constant(appearance.colours.map(\.swiftUIColor)),
				speed: .constant(appearance.speed),
				bias: .constant(1),
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
	private func badgeStack(size: CGFloat) -> some View {
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
