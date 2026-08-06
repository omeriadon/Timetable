import SwiftUI

private struct AppNavigationTitleModifier: ViewModifier {
	let title: String
	let style: AppNavigationTitleStyle
	let usesAccentColor: Bool

	func body(content: Content) -> some View {
		content
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text(title)
						.font(style == .main ? .largeTitle : .title2)
						.bold()
						.monospaced()
						.foregroundStyle(usesAccentColor ? .accent : .primary)
						.lineLimit(2)
				}
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.scrollEdgeEffectStyle(.soft, for: .bottom)
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
