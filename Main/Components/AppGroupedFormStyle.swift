import SwiftUI

extension View {
	@ViewBuilder
	func appGroupedFormStyle() -> some View {
		#if os(macOS)
			formStyle(.grouped)
				.scrollContentBackground(.hidden)
		#else
			self
		#endif
	}
}
