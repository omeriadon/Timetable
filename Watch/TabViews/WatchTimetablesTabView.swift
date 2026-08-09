import Defaults
import SwiftUI

private extension View {
	func watchCardStyle(cornerRadius: CGFloat = 24) -> some View {
		background {
			WatchPaperBackground(imageName: "paper", cornerRadius: cornerRadius)
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
	let cornerRadius: CGFloat
	let usesBackground: Bool
	@ViewBuilder var content: Content

	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content
	) {
		self.verticalInset = verticalInset
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
		.padding(.horizontal, 8)
		.padding(.vertical, verticalInset)
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	private let verticalCardInset: CGFloat = 8

	var body: some View {
		TabView {
			WatchPage(
				verticalInset: verticalCardInset,
				usesBackground: false
			) {
				ContentView()
			}

			if !subjects.isEmpty {
				WatchPage(verticalInset: verticalCardInset) {
					CurrentSubjectView()
				}
			}

			ForEach(friends) { friend in
				if let timetable = friend.timetable {
					WatchPage(verticalInset: verticalCardInset) {
						FriendsTimetablesView(friend: friend, timetable: timetable)
					}
				}
			}
		}
		.tabViewStyle(.verticalPage)
		.dynamicTypeSize(.xSmall)
		.ignoresSafeArea(.container, edges: .vertical)
		.background {
			WatchPaperBackground(imageName: "paperGray", cornerRadius: 0)
				.ignoresSafeArea()
		}
		.ignoresSafeArea()
	}
}
