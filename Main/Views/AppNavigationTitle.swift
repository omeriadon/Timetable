import SwiftUI

enum AppNavigationTitleStyle {
	case main
	case subview
}

extension View {
	@ViewBuilder
	func appNavigationTitle(_ title: String, style: AppNavigationTitleStyle = .subview) -> some View {
		navigationTitle(title)
		#if os(iOS)
			.navigationBarTitleDisplayMode(style == .main ? .large : .inline)
			.toolbar {
				ToolbarItem(placement: style == .main ? .largeTitle : .principal) {
					HStack {
						Text(title)
							.font(style == .main ? .largeTitle : .title2)
							.bold()
							.monospaced()
						Spacer(minLength: 1)
					}
				}
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.scrollEdgeEffectStyle(.soft, for: .bottom)
		#endif // os(iOS)
	}
}
