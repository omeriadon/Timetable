import SwiftUI

extension View {
	@ViewBuilder
	func appNavigationTitle(_ title: String) -> some View {
		navigationTitle(title)
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}
