import SwiftUI

struct AdaptiveAppShell: View {
	@Environment(\.appPresentation) private var presentation

	var body: some View {
		switch presentation {
			case .iOS:
				CompactAppShell()
			case .iPadOS, .macOS:
				WideAppShell()
		}
	}
}
