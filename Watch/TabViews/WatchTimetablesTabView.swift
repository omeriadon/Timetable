import Defaults
import SwiftUI

private extension View {
	func watchCardStyle(cornerRadius: CGFloat = 24) -> some View {
		background {
			WatchPaperBackground(imageName: "paper", cornerRadius: cornerRadius)
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		.overlay {
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.strokeBorder(.white.opacity(0.5), lineWidth: 2)
		}
		.foregroundStyle(.white)
	}
}

private struct WatchPaperBackground: View {
	let imageName: String
	let cornerRadius: CGFloat

	var body: some View {
		GeometryReader { proxy in
			Image(imageName)
				.resizable()
				.scaledToFill()
				.frame(width: proxy.size.width, height: proxy.size.height)
				.clipped()
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
	}
}

private struct WatchPage<Content: View>: View {
	let height: CGFloat
	let verticalInset: CGFloat
	let horizontalPadding: CGFloat
	let cornerRadius: CGFloat
	let usesBackground: Bool
	@ViewBuilder var content: Content

	init(
		height: CGFloat,
		verticalInset: CGFloat,
		horizontalPadding: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content
	) {
		self.height = height
		self.verticalInset = verticalInset
		self.horizontalPadding = horizontalPadding
		self.cornerRadius = cornerRadius
		self.usesBackground = usesBackground
		self.content = content()
	}

	@ViewBuilder
	private func styled(_ view: some View) -> some View {
		if usesBackground {
			view.watchCardStyle(cornerRadius: cornerRadius)
		} else {
			view.foregroundStyle(.white)
		}
	}

	var body: some View {
		styled(
			content
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		)
		.padding(.horizontal, horizontalPadding)
		.padding(.vertical, verticalInset)
		.frame(height: height)
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	private let cardSpacing: CGFloat = 8
	private let peekHeight: CGFloat = 18
	private let secondaryCardHeightReduction: CGFloat = 36
	private let verticalCardInset: CGFloat = 8

	var body: some View {
		GeometryReader { proxy in
			let firstPageHeight = max(1, proxy.size.height - peekHeight * 2)
			let secondaryPageHeight = max(1, firstPageHeight - secondaryCardHeightReduction)

			ScrollView(.vertical) {
				LazyVStack(spacing: cardSpacing) {
					WatchPage(
						height: firstPageHeight,
						verticalInset: verticalCardInset,
						horizontalPadding: 3,
						usesBackground: false
					) {
						ContentView()
					}

					if !subjects.isEmpty {
						WatchPage(
							height: secondaryPageHeight,
							verticalInset: verticalCardInset,
							horizontalPadding: 8
						) {
							CurrentSubjectView()
						}
					}

					ForEach(friends) { friend in
						if let timetable = friend.timetable {
							WatchPage(
								height: secondaryPageHeight,
								verticalInset: verticalCardInset,
								horizontalPadding: 8
							) {
								FriendsTimetablesView(friend: friend, timetable: timetable)
							}
						}
					}
				}
				.scrollTargetLayout()
			}
			.contentMargins(.vertical, peekHeight, for: .scrollContent)
			.scrollTargetBehavior(.viewAligned(limitBehavior: .always, anchor: .center))
			.scrollClipDisabled()
		}
		.dynamicTypeSize(.xSmall)
		.ignoresSafeArea(.container, edges: .vertical)
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
				.ignoresSafeArea()
		}
	}
}
