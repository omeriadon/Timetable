import Defaults
import SwiftUI
import WatchKit

private extension View {
	func watchCardStyle(cornerRadius: CGFloat = 24) -> some View {
		background {
			WatchPaperBackground(imageName: "paper", cornerRadius: cornerRadius)
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
	let verticalInset: CGFloat
	let horizontalPadding: CGFloat
	let cornerRadius: CGFloat
	let sizesToFitContent: Bool
	let pageAlignment: VerticalAlignment
	let peekHeight: CGFloat
	@ViewBuilder var content: Content

	init(
		verticalInset: CGFloat,
		horizontalPadding: CGFloat,
		cornerRadius: CGFloat = 24,
		sizesToFitContent: Bool = false,
		pageAlignment: VerticalAlignment = .top,
		peekHeight: CGFloat = 0,
		@ViewBuilder content: () -> Content
	) {
		self.verticalInset = verticalInset
		self.horizontalPadding = horizontalPadding
		self.cornerRadius = cornerRadius
		self.sizesToFitContent = sizesToFitContent
		self.pageAlignment = pageAlignment
		self.peekHeight = peekHeight
		self.content = content()
	}

	var body: some View {
		Group {
			if sizesToFitContent {
				content
					.frame(maxWidth: .infinity)
			} else {
				content
					.frame(maxWidth: .infinity)
					.containerRelativeFrame(.vertical) { length, _ in
						max(1, length - verticalInset * 2)
					}
			}
		}
		.watchCardStyle(cornerRadius: cornerRadius)
		.padding(.horizontal, horizontalPadding)
		.padding(.vertical, verticalInset)
		.containerRelativeFrame(.vertical, alignment: Alignment(horizontal: .center, vertical: pageAlignment)) { length, _ in
			max(1, length - peekHeight)
		}
		.scrollTransition(.animated(.smooth), axis: .vertical) { view, phase in
			let magnitude = min(abs(phase.value), 1)
			return view
				.scaleEffect(1 - magnitude * 0.08)
				.blur(radius: magnitude * 4)
				.opacity(1 - magnitude * 0.2)
		}
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	var body: some View {
		ScrollView(.vertical) {
			VStack(spacing: 0) {
				WatchPage(verticalInset: 10, horizontalPadding: 3, cornerRadius: 13, sizesToFitContent: true, pageAlignment: .center, peekHeight: 10) {
					ContentView()
				}
				.padding(.top, 18)

				if !subjects.isEmpty {
					WatchPage(verticalInset: 50, horizontalPadding: 8, peekHeight: 70) {
						CurrentSubjectView()
					}
				}

				ForEach(friends) { friend in
					if let timetable = friend.timetable {
						WatchPage(verticalInset: 50, horizontalPadding: 8, peekHeight: 70) {
							FriendsTimetablesView(friend: friend, timetable: timetable)
						}
					}
				}
			}
			.scrollTargetLayout()
		}
		.dynamicTypeSize(.xSmall)
		.scrollTargetBehavior(.viewAligned(limitBehavior: .always))
		.scrollClipDisabled()
		.ignoresSafeArea(.container, edges: .vertical)
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
				.ignoresSafeArea()
		}
	}
}
