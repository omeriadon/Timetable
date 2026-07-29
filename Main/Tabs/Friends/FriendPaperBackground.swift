import SwiftUI

struct FriendPaperBackground: View {
	let cornerRadius: CGFloat

	var body: some View {
		GeometryReader { proxy in
			Image("paperWhite")
				.resizable()
				.scaledToFill()
				.frame(
					width: proxy.size.width,
					height: proxy.size.height
				)
				.clipped()
		}
		.clipShape(
			RoundedRectangle(
				cornerRadius: cornerRadius,
				style: .continuous
			)
		)
	}
}
