import ColorfulX
import Defaults
import ImageIO
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
	private let visibleBadges: [ProfileBadge]
	let accessibilityName: String
	let animatesBackground: Bool
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	init(
		appearance: ProfileAppearance,
		photo: ProfilePhotoMetadata? = nil,
		size: CGFloat? = nil,
		badges: [ProfileBadge] = [],
		accessibilityName: String,
		animatesBackground: Bool = true
	) {
		self.appearance = appearance
		photoSource = photo.map(PhotoSource.remote)
		self.size = size
		self.badges = badges
		visibleBadges = Self.visibleBadges(from: badges)
		self.accessibilityName = accessibilityName
		self.animatesBackground = animatesBackground
	}

	init(
		size: CGFloat? = nil,
		accessibilityName: String = "Profile Picture",
		animatesBackground: Bool = true
	) {
		let profile = Defaults[.accountProfile]
		appearance = profile?.appearance ?? Defaults[.profileAppearance]
		photoSource = profile?.photo.map(PhotoSource.remote)
		self.size = size
		badges = profile?.badges ?? []
		visibleBadges = Self.visibleBadges(from: profile?.badges ?? [])
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
		visibleBadges = Self.visibleBadges(from: badges)
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
						.font(monogramFont)
						.foregroundStyle(appearance.foregroundColour.swiftUIColor)
						.animation(
							reduceMotion ? .none : .easeInOut(duration: 0.2),
							value: appearance.foregroundColour
						)
						.minimumScaleFactor(0.01)
						.padding(size * 0.15)

				case .emoji:
					Text(appearance.emoji)
						.font(.system(size: 150))
						.foregroundStyle(appearance.foregroundColour.swiftUIColor)
						.animation(
							reduceMotion ? .none : .easeInOut(duration: 0.2),
							value: appearance.foregroundColour
						)
						.minimumScaleFactor(0.01)
						.padding(size * 0.15)
			}
		}
	}

	private var monogramFont: Font {
		switch appearance.fontDesign {
			case .default:
				Font(UIFont.systemFont(ofSize: 150, weight: monogramUIFontWeight))
			case .serif:
				Font(designedSystemFont(.serif))
			case .monospaced:
				Font(UIFont.monospacedSystemFont(ofSize: 150, weight: monogramUIFontWeight))
			case .rounded:
				Font(designedSystemFont(.rounded))
		}
	}

	private func designedSystemFont(_ design: UIFontDescriptor.SystemDesign) -> UIFont {
		let weightedDescriptor = UIFont.systemFont(
			ofSize: 150,
			weight: monogramUIFontWeight
		).fontDescriptor
		let designedDescriptor = weightedDescriptor.withDesign(design) ?? weightedDescriptor
		return UIFont(descriptor: designedDescriptor, size: 150)
	}

	private var monogramUIFontWeight: UIFont.Weight {
		switch appearance.fontWeight {
			case .ultraLight:
				.ultraLight
			case .thin:
				.thin
			case .light:
				.light
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
			case .black:
				.black
		}
	}

	@ViewBuilder
	private var profileBackground: some View {
		if animatesBackground, !reduceMotion, appearance.contentKind != .photo {
			ColorfulView(
				color: .constant(appearance.colours.map(\.swiftUIColor)),
				speed: .constant(appearance.speed),
				bias: .constant(0.000000000000001),
				noise: .constant(appearance.noise),
				transitionSpeed: .constant(4),
				frameLimit: .constant(30),
				renderScale: .constant(6)
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
								.stroke(.white.opacity(0.85), lineWidth: 0.5)
						}
						.zIndex(Double(badge.priority))
						.accessibilityLabel(badge.accessibilityLabel)
				}
			}
		}
	}

	private var badgeAccessibilityValue: String? {
		let labels = visibleBadges.map(\.accessibilityLabel)
		return labels.isEmpty ? nil : labels.joined(separator: ", ")
	}

	private static func visibleBadges(from badges: [ProfileBadge]) -> [ProfileBadge] {
		Array(badges.sorted { $0.priority > $1.priority }.prefix(3))
	}
}

extension AccountProfile {
	var profilePictureNoise: Double {
		appearance.contentKind == .photo ? ProfilePictureVisuals.photoNoise : appearance.noise
	}

	var profilePictureSpeed: Double {
		appearance.contentKind == .photo ? ProfilePictureVisuals.photoSpeed : appearance.speed
	}

	func profilePictureColours() async -> [RGBAColor] {
		await ProfilePictureVisuals.colours(
			for: appearance,
			photo: photo
		)
	}
}

enum ProfilePictureVisuals {
	static let photoNoise = 20.0
	static let photoSpeed = 0.9

	static func colours(
		for appearance: ProfileAppearance,
		photo: ProfilePhotoMetadata?
	) async -> [RGBAColor] {
		guard appearance.contentKind == .photo,
		      let photo,
		      let data = await ProfileImageCache.shared.imageData(for: photo, displaySize: 96),
		      let palette = await palette(from: data),
		      !palette.isEmpty
		else {
			return Array(appearance.colours.prefix(3))
		}

		return palette
	}

	private static func palette(from data: Data) async -> [RGBAColor]? {
		await Task.detached(priority: .userInitiated) {
			guard let source = CGImageSourceCreateWithData(data as CFData, nil),
			      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
			      let providerData = image.dataProvider?.data,
			      let bytes = CFDataGetBytePtr(providerData),
			      image.bitsPerPixel == 32
			else {
				return nil
			}

			let width = image.width
			let height = image.height
			let bytesPerPixel = image.bitsPerPixel / 8
			let isLittleEndian = image.bitmapInfo.contains(.byteOrder32Little)
			var bins: [PaletteBin: Int] = [:]

			for y in stride(from: 0, to: height, by: max(1, height / 24)) {
				for x in stride(from: 0, to: width, by: max(1, width / 24)) {
					let offset = y * image.bytesPerRow + x * bytesPerPixel
					let first = Double(bytes[offset]) / 255
					let second = Double(bytes[offset + 1]) / 255
					let third = Double(bytes[offset + 2]) / 255
					let alpha = Double(bytes[offset + 3]) / 255

					guard alpha > 0.2 else {
						continue
					}

					let red = isLittleEndian ? third : first
					let green = second
					let blue = isLittleEndian ? first : third
					let bin = PaletteBin(
						red: Int(red * 12),
						green: Int(green * 12),
						blue: Int(blue * 12)
					)
					bins[bin, default: 0] += 1
				}
			}

			return bins
				.sorted { $0.value > $1.value }
				.prefix(3)
				.map { bin, _ in
					RGBAColor(
						red: (Double(bin.red) + 0.5) / 12,
						green: (Double(bin.green) + 0.5) / 12,
						blue: (Double(bin.blue) + 0.5) / 12,
						alpha: 1
					)
				}
		}.value
	}

	private nonisolated struct PaletteBin: Hashable, Sendable {
		let red: Int
		let green: Int
		let blue: Int
	}
}
