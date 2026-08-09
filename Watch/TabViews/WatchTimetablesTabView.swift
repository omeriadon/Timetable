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

private struct WatchPage<Content: View, Top: View, Status: View>: View {
	let verticalInset: CGFloat
	let cornerRadius: CGFloat
	let usesBackground: Bool
	let content: Content
	let top: Top
	let status: Status

	let shorter: Bool

	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		shorter: Bool = false,
		@ViewBuilder content: () -> Content,
		@ViewBuilder top: () -> Top,
		@ViewBuilder status: () -> Status
	) {
		self.verticalInset = verticalInset
		self.cornerRadius = cornerRadius
		self.usesBackground = usesBackground
		self.shorter = shorter
		self.content = content()
		self.top = top()
		self.status = status()
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
		VStack(spacing: 5) {
			top

			styled(
				content
			)
			.padding(.horizontal, 8)

			status
		}
		.padding(.top, 35)
		.padding(.bottom, 20)
		.padding(.trailing, 3)
		.padding(.vertical, shorter ? 20 : 0)
		.ignoresSafeArea()
	}
}

private extension WatchPage where Top == EmptyView, Status == EmptyView {
	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		shorter: Bool = false,
		@ViewBuilder content: () -> Content
	) {
		self.init(
			verticalInset: verticalInset,
			cornerRadius: cornerRadius,
			usesBackground: usesBackground,
			shorter: shorter,
			content: content,
			top: { EmptyView() },
			status: { EmptyView() }
		)
	}
}

private extension WatchPage where Top == EmptyView {
	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content,
		@ViewBuilder status: () -> Status
	) {
		self.init(
			verticalInset: verticalInset,
			cornerRadius: cornerRadius,
			usesBackground: usesBackground,
			content: content,
			top: { EmptyView() },
			status: status
		)
	}
}

private extension WatchPage where Status == EmptyView {
	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content,
		@ViewBuilder top: () -> Top
	) {
		self.init(
			verticalInset: verticalInset,
			cornerRadius: cornerRadius,
			usesBackground: usesBackground,
			content: content,
			top: top,
			status: { EmptyView() }
		)
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	private let verticalCardInset: CGFloat = 2

	var body: some View {
		TabView {
			WatchPage(
				verticalInset: verticalCardInset,
				usesBackground: false
			) {
				ContentView()
			}

			if !subjects.isEmpty {
				WatchPage(verticalInset: verticalCardInset, shorter: true) {
					CurrentSubjectView()
				}
			}

			ForEach(friends) { friend in
				if let timetable = friend.timetable {
					WatchPage(verticalInset: verticalCardInset) {
						FriendsTimetablesView(friend: friend, timetable: timetable)
					} top: {
						Text(friend.friend.displayName)
							.font(.title3)
							.bold()
							.lineLimit(1)
							.multilineTextAlignment(.center)
					} status: {
						WatchLocationStatusView(item: friend.locationStatus)
					}
				}
			}
		}
		.tabViewStyle(.verticalPage)
		.dynamicTypeSize(.xSmall)
		.background {
			WatchPaperBackground(imageName: "paperGray", cornerRadius: 0)
				.ignoresSafeArea()
		}
		.ignoresSafeArea()
	}
}

private struct WatchLocationStatusView: View {
	let item: LocationStatusItem?

	var body: some View {
		TimelineView(.periodic(from: .now, by: 60)) { context in
			let now = TimetableClock.adjusted(context.date)
			let title = item.map { $0.state == .onCampus ? "On Campus" : "Off Campus" } ?? "Status unavailable"
			let tint = item.map { statusTint(for: $0.state, at: now) } ?? .secondary

			HStack(spacing: 4) {
				Text(title)

				if let item {
					Spacer(minLength: 1)

					Text(item.updatedAt, format: .dateTime.hour().minute())
						.foregroundStyle(.secondary)
				}
			}
			.font(.caption2.scaled(by: 0.8))
			.foregroundStyle(.white)
			.padding(3)
			.padding(.horizontal, 1.5)
			.glassEffect(.clear.tint(tint).interactive(), in: Capsule())
		}
		.padding(.horizontal, item != nil ? 25 : 0)
	}

	private func statusTint(for state: LocationStatus, at date: Date) -> Color {
		guard state == .offCampus else { return .green }

		let calendar = SchoolCalendarProjection.perthCalendar
		let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
		guard
			let weekday = components.weekday,
			let hour = components.hour,
			let minute = components.minute
		else {
			return .blue
		}

		let minutes = hour * 60 + minute
		let schoolEnd: Int

		switch weekday {
			case 2, 3, 5:
				schoolEnd = 15 * 60 + 30
			case 4, 6:
				schoolEnd = 14 * 60 + 30
			default:
				return .blue
		}

		return minutes >= 8 * 60 + 50 && minutes < schoolEnd ? .red : .blue
	}
}
