import SwiftUI
#if os(iOS)
	import PortalHeaders
#endif

enum AppNavigationTitleStyle {
	case main
	case subview
}

extension View {
	@ViewBuilder
	func appNavigationTitle(_ title: String, style _: AppNavigationTitleStyle = .subview) -> some View {
		#if os(iOS)
			portalHeader(title: title, subtitle: "")
				.portalHeaderDestination()
				.scrollEdgeEffectStyle(.soft, for: .top)
				.scrollEdgeEffectStyle(.soft, for: .bottom)
		#else
			navigationTitle(title)
		#endif // os(iOS)
	}
}

struct AppNavigationHeader: View {
	var body: some View {
		#if os(iOS)
			PortalHeaderView()
				.monospaced()
		#else
			EmptyView()
		#endif
	}
}
