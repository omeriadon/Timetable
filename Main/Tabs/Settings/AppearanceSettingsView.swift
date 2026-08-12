import Defaults
import SwiftUI

struct AppearanceSettingsView: View {
	@State private var settings = Defaults[.accountSettings]
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var settingsSync = AccountSettingsSyncService.shared
	@State private var saveGeneration = 0
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			Section("App Font") {
				Picker("App Font", systemImage: "character", selection: appFontDesignBinding) {
					ForEach(AppFontDesign.allCases) { design in
						Text(design.title)
							.fontDesign(design.swiftUIFontDesign)
							.fontWidth(design.swiftUIFontWidth)
							.tag(design)
					}
				}
			}
			.glurListRowBackground()

			Section("Background") {
				ForEach(AppBackground.allCases) { background in
					AppBackgroundSelectionRow(
						background: background,
						isSelected: settings.appBackground == background,
						select: { select(background) }
					)
					.listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
					.listRowBackground(Color.clear)
				}
			}
		}
		.appPaperBackground()
		.appNavigationTitle("Appearance", accent: true)
	}

	private var appFontDesignBinding: Binding<AppFontDesign> {
		Binding(
			get: { settings.appFontDesign },
			set: { design in
				settings.appFontDesign = design
				save(settings)
			}
		)
	}

	private func select(_ background: AppBackground) {
		guard settings.appBackground != background else {
			return
		}

		settings.appBackground = background
		save(settings)
	}

	private func save(_ proposedSettings: AccountSettings) {
		saveGeneration += 1
		let generation = saveGeneration
		let previous = committedSettings

		Task {
			do {
				try await settingsSync.updateSettings(proposedSettings)
				guard generation == saveGeneration else { return }
				committedSettings = proposedSettings
			} catch {
				guard generation == saveGeneration else { return }
				settings = previous
				badges.addBadge(
					id: UUID(),
					title: "Unable to save appearance",
					secondaryText: error.localizedDescription,
					priority: 4,
					view: .error
				)
			}
		}
	}
}
