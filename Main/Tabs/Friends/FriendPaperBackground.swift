import SwiftUI

struct FriendGrayPaperBackground: View {
	let cornerRadius: CGFloat

	var body: some View {
		GeometryReader { proxy in
			Image("paperGray")
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

struct FriendBackgroundPaperBackground: View {
	let cornerRadius: CGFloat

	var body: some View {
		GeometryReader { proxy in
			Image("backgroundPaper")
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

struct FriendForegroundPaperBackground: View {
	let cornerRadius: CGFloat

	var body: some View {
		GeometryReader { proxy in
			Image("foregroundPaper")
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

struct FriendBrownPaperBackground: View {
	let shape: AnyShape

	init(cornerRadius: CGFloat) {
		shape = AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
	}

	init(shape: AnyShape) {
		self.shape = shape
	}

	var body: some View {
		GeometryReader { proxy in
			Image("paper")
				.resizable()
				.scaledToFill()
				.frame(width: proxy.size.width, height: proxy.size.height)
				.clipped()
		}
		.clipShape(shape)
	}
}

struct FriendWhitePaperBackground: View {
	let shape: AnyShape

	init(cornerRadius: CGFloat) {
		shape = AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
	}

	init(shape: AnyShape) {
		self.shape = shape
	}

	var body: some View {
		GeometryReader { proxy in
			Image("paperWhite")
				.resizable()
				.scaledToFill()
				.frame(width: proxy.size.width, height: proxy.size.height)
				.clipped()
		}
		.clipShape(shape)
	}
}
