import ColorfulX
import Defaults
import SwiftUI

struct ProfileAppearanceSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Default(.accountProfile) private var accountProfile
	@Default(.profileAppearance) private var savedAppearance
	@State private var service = FriendService.shared
	@State private var displayName = ""
	@State private var usesMonogram = false
	@State private var monogram = ""
	@State private var selectedSymbol = "paperplane.fill"
	@State private var colors: [Color] = [.blue, .purple, .pink]
	@State private var speed = 0.2
	@State private var noise = 64.0
	@State private var selectedFont = ProfileFont.rounded
	@State private var isSaving = false
	@Environment(\.statusBadgeManager) private var badges

	private let symbols = [
		"paperplane.fill",
		"star.fill",
		"bolt.fill",
		"paintpalette.fill",
		"book.fill",
		"figure.run",
		"music.note",
		"gamecontroller.fill",
	]

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					avatarPreview

					TextField("Account name", text: $displayName)
						.textFieldStyle(.roundedBorder)

					Picker("Appearance layer", selection: $usesMonogram) {
						Label("Symbol", systemImage: "sparkles").tag(false)
						Label("Monogram", systemImage: "character").tag(true)
					}
					.pickerStyle(.segmented)

					if usesMonogram {
						TextField("Up to 3 letters", text: $monogram)
							.textInputAutocapitalization(.characters)
							.autocorrectionDisabled()
							.textFieldStyle(.roundedBorder)
							.onChange(of: monogram) { _, value in
								monogram = String(value.prefix(3)).uppercased()
							}
						Picker("Font", selection: $selectedFont) {
							ForEach(ProfileFont.allCases) { font in
								Text(font.title).tag(font)
							}
						}
					} else {
						LazyVGrid(columns: [GridItem(.adaptive(minimum: 54))], spacing: 10) {
							ForEach(symbols, id: \.self) { symbol in
								Button(symbol, systemImage: symbol) {
									selectedSymbol = symbol
								}
								.buttonStyle(.glass)
								.tint(selectedSymbol == symbol ? .accentColor : .secondary)
							}
						}
					}

					VStack(alignment: .leading, spacing: 10) {
						Text("Background")
							.font(.headline)
						ColorPicker("Primary colour", selection: colorBinding(index: 0))
						ColorPicker("Secondary colour", selection: colorBinding(index: 1))
						ColorPicker("Accent colour", selection: colorBinding(index: 2))
						Slider(value: $speed, in: 0 ... 2) { Text("Speed") }
						Slider(value: $noise, in: 0 ... 200) { Text("Noise") }
					}
					.padding()
					.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
				}
				.padding()
			}
			.scrollEdgeEffect()
			.appNavigationTitle("Profile", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					} label: {
						Image(systemName: "xmark")
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						save()
					}
					.buttonStyle(.glassProminent)
					.disabled(isSaving)
				}
			}
			.task { loadAppearance() }
		}
	}

	private var avatarPreview: some View {
		ZStack {
			ColorfulView(
				color: $colors,
				speed: $speed,
				bias: .constant(0.00001),
				noise: $noise,
				transitionSpeed: .constant(10),
				frameLimit: .constant(60),
				renderScale: .constant(0.9)
			)
			if usesMonogram {
				Text(monogram.isEmpty ? initials : monogram)
					.font(selectedFont.font)
					.foregroundStyle(.white)
			} else {
				Image(systemName: selectedSymbol)
					.font(.system(size: 56, weight: .medium))
					.foregroundStyle(.white)
			}
		}
		.frame(width: 150, height: 150)
		.clipShape(Circle())
		.shadow(radius: 12)
	}

	private var initials: String {
		let parts = displayName.split(separator: " ")
		return String(parts.prefix(3).compactMap(\.first))
	}

	private func colorBinding(index: Int) -> Binding<Color> {
		Binding(
			get: { colors[index] },
			set: { colors[index] = $0 }
		)
	}

	private func loadAppearance() {
		displayName = accountProfile?.displayName ?? ""
		usesMonogram = savedAppearance.usesMonogram
		monogram = savedAppearance.monogram
		selectedSymbol = savedAppearance.symbol
		selectedFont = ProfileFont(rawValue: savedAppearance.font) ?? .rounded
		colors = savedAppearance.colours.map(\.swiftUIColor)
		speed = savedAppearance.speed
		noise = savedAppearance.noise
	}

	private func save() {
		let appearance = ProfileAppearance(
			usesMonogram: usesMonogram,
			monogram: monogram,
			symbol: selectedSymbol,
			font: selectedFont.rawValue,
			colours: colors.map { RGBAColor(color: $0) },
			speed: speed,
			noise: noise
		)
		isSaving = true
		Task {
			defer { isSaving = false }
			do {
				if displayName != accountProfile?.displayName {
					_ = try await SessionStore.shared.updateProfile(displayName: displayName)
				}
				try await service.updateProfileAppearance(appearance)
				dismiss()
			} catch {
				badges.present(error: error, title: "Unable to save profile")
			}
		}
	}
}

private enum ProfileFont: String, CaseIterable, Identifiable {
	case `default`
	case serif
	case monospaced
	case rounded

	var id: String {
		rawValue
	}

	var title: String {
		rawValue.capitalized
	}

	var font: Font {
		switch self {
			case .default: .system(size: 52, weight: .semibold)
			case .serif: .system(size: 52, weight: .semibold, design: .serif)
			case .monospaced: .system(size: 52, weight: .semibold, design: .monospaced)
			case .rounded: .system(size: 52, weight: .semibold, design: .rounded)
		}
	}
}
