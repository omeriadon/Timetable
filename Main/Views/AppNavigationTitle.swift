import SwiftUI

private struct AppNavigationTitleModifier: ViewModifier {
	@Environment(\.dismiss) private var dismiss

	let title: String
	let style: AppNavigationTitleStyle
	let usesAccentColor: Bool

	func body(content: Content) -> some View {
		#if os(iOS)
			content
				.appNavigationTitle(title)
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .principal) {
						Text(title)
							.font(style == .main ? .largeTitle : .title2)
							.bold()
							.monospaced()
							.foregroundStyle(usesAccentColor ? .accent : .primary)
					}
				}
				.scrollEdgeEffectStyle(.soft, for: .top)
				.scrollEdgeEffectStyle(.soft, for: .bottom)
		#elseif os(macOS)
			if style == .subview {
				content
					.appNavigationTitle(title)
					.navigationBarBackButtonHidden(true)
					.toolbar {
						ToolbarItem(placement: .navigation) {
							Button(action: { dismiss() }) {
								Image(systemName: "chevron.left")
									.frame(width: 24, height: 24)
							}
							.buttonStyle(.borderless)
							.help("Back")
						}
					}
			} else {
				content.appNavigationTitle(title)
			}
		#else
			content.appNavigationTitle(title)
		#endif
	}
}

enum AppNavigationTitleStyle {
	case main
	case subview
}

extension View {
	func appNavigationTitle(_ title: String, style: AppNavigationTitleStyle = .subview, accent: Bool = true) -> some View {
		modifier(AppNavigationTitleModifier(title: title, style: style, usesAccentColor: accent))
	}
}
