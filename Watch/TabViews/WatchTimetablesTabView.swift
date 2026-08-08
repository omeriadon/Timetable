import Defaults
import SwiftUI
import WatchKit

private extension View {
	func watchPageCard(height: CGFloat) -> some View {
		frame(height: height)
			.frame(maxWidth: .infinity)
			.background {
				WatchPaperBackground(
					imageName: "paper",
					cornerRadius: 24
				)
			}
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	private var screenHeight: CGFloat {
		WKInterfaceDevice.current().screenBounds.height
	}

	private var cardHeight: CGFloat {
		max(1, screenHeight - 24)
	}

	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 0) {
				ContentView()
					.watchPageCard(height: cardHeight)
					.padding(.horizontal, 8)
					.padding(.vertical, 12)

				if !subjects.isEmpty {
					CurrentSubjectView()
						.watchPageCard(height: cardHeight)
						.padding(.horizontal, 8)
						.padding(.vertical, 12)
				}

				ForEach(friends) { friend in
					if let timetable = friend.timetable {
						FriendsTimetablesView(friend: friend, timetable: timetable)
							.watchPageCard(height: cardHeight)
							.padding(.horizontal, 8)
							.padding(.vertical, 12)
					}
				}
			}
			.scrollTargetLayout()
		}
		.scrollTargetBehavior(.viewAligned(limitBehavior: .always))
		.scrollClipDisabled()
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
		}
	}
}
