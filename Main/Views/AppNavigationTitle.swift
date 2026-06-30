import SwiftUI

extension View {
	@ViewBuilder
	func appNavigationTitle(_ title: String) -> some View {
		#if os(iOS)
			toolbar {
				ToolbarItem(placement: .largeSubtitle) {
					Text(title).monospaced()
				}
			}
		#else
			toolbar {
				ToolbarItem(placement: .principal) {
					Text(title).monospaced()
				}
			}
		#endif
	}
}
