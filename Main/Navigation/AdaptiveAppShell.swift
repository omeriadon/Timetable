import SwiftUI

struct AdaptiveAppShell: View {
	@Environment(\.appPresentation) private var presentation
	@Binding var expanded: WindowMode

	var body: some View {
		#if os(macOS)
			WideAppShell(expanded: $expanded)
		#else
			switch presentation {
				case .iOS:
				CompactAppShell()
				case .iPadOS, .macOS:
				WideAppShell(expanded: $expanded)
			}
		#endif
	}
}
