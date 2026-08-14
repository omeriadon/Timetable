import SwiftUI

struct AppBackgroundSurface: View {
	let background: AppBackground
	@Environment(\.colorScheme) private var colorScheme

	var body: some View {
		GeometryReader { proxy in
			backgroundContent
				.frame(
					width: proxy.size.width,
					height: proxy.size.height,
					alignment: .center
				)
				.clipped()
		}
		.accessibilityHidden(true)
	}

	@ViewBuilder
	private var backgroundContent: some View {
		switch background {
			case .solid:
				Color(white: colorScheme == .dark ? 0 : 1)
			case .paper:
				backgroundImage(named: colorScheme == .dark ? "backgroundPaper" : "paperWhite")
		}
	}

	private func backgroundImage(named name: String) -> some View {
		Image(name)
			.resizable()
			.scaledToFill()
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
	}
}
