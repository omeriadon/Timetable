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
		#endif // os(iOS)
	}
}
