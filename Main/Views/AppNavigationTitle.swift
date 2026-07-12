import SwiftUI

private struct AppNavigationTitleModifier: ViewModifier {
	@Environment(\.dismiss) private var dismiss

	let title: String
	let style: AppNavigationTitleStyle

	func body(content: Content) -> some View {
		#if os(iOS)
			content
				.navigationTitle(title)
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .principal) {
						Text(title)
							.font(style == .main ? .largeTitle : .title2)
							.bold()
							.monospaced()
					}
				}
				.scrollEdgeEffectStyle(.soft, for: .top)
				.scrollEdgeEffectStyle(.soft, for: .bottom)
		#elseif os(macOS)
			if style == .subview {
				content
					.navigationTitle(title)
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
				content.navigationTitle(title)
			}
		#else
			content.navigationTitle(title)
		#endif
	}
}

enum AppNavigationTitleStyle {
	case main
	case subview
}

extension View {
	func appNavigationTitle(_ title: String, style: AppNavigationTitleStyle = .subview) -> some View {
		modifier(AppNavigationTitleModifier(title: title, style: style))
	}
}
