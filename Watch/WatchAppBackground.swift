import SwiftUI

struct WatchAppBackground: View {
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
			case .systemGray:
				Color.gray
			case .blackPaper:
				backgroundImage(named: colorScheme == .dark ? "paperBlack" : "paperWhite")
			case .grayPaper:
				backgroundImage(named: "paperGray")
			case .brownPaper:
				backgroundImage(named: "paper")
			case .dome:
				backgroundImage(named: "appBackgroundDome")
			case .peak:
				backgroundImage(named: "appBackgroundPeak")
			case .tree:
				backgroundImage(named: "appBackgroundTree")
			case .valley:
				backgroundImage(named: "appBackgroundValley")
		}
	}

	private func backgroundImage(named name: String) -> some View {
		Image(name)
			.resizable()
			.scaledToFill()
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
	}
}
