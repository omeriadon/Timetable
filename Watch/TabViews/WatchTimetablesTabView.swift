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

private struct WatchPage<Content: View, Status: View>: View {
	let verticalInset: CGFloat
	let cornerRadius: CGFloat
	let usesBackground: Bool
	let content: Content
	let status: Status

	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content,
		@ViewBuilder status: () -> Status
	) {
		self.verticalInset = verticalInset
		self.cornerRadius = cornerRadius
		self.usesBackground = usesBackground
		self.content = content()
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
		VStack(spacing: 0) {
			styled(
				content
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			)
			.padding(.horizontal, 8)
			.padding(.vertical, verticalInset)

			status
		}
	}
}

private extension WatchPage where Status == EmptyView {
	init(
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content
	) {
		self.init(
			verticalInset: verticalInset,
			cornerRadius: cornerRadius,
			usesBackground: usesBackground,
			content: content,
			status: { EmptyView() }
		)
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.locationStatus) private var locationStatus
	@Default(.timetable) private var subjects

	private let verticalCardInset: CGFloat = 8

	var body: some View {
		TabView {
			WatchPage(
				verticalInset: verticalCardInset,
				usesBackground: false
			) {
				ContentView()
			} status: {
				WatchLocationStatusView(item: locationStatus)
			}

			if !subjects.isEmpty {
				WatchPage(verticalInset: verticalCardInset) {
					CurrentSubjectView()
				} status: {
					WatchLocationStatusView(item: locationStatus)
				}
			}

			ForEach(friends) { friend in
				if let timetable = friend.timetable {
					WatchPage(verticalInset: verticalCardInset) {
						FriendsTimetablesView(friend: friend, timetable: timetable)
					} status: {
						WatchLocationStatusView(item: friend.locationStatus)
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

private struct WatchLocationStatusView: View {
	let item: LocationStatusItem?

	var body: some View {
		TimelineView(.periodic(from: .now, by: 60)) { context in
			let now = TimetableClock.adjusted(context.date)
			let title = item.map { $0.state == .onCampus ? "On Campus" : "Off Campus" } ?? "Status unavailable"
			let symbol = item.map { $0.state == .onCampus ? "location.fill" : "location.slash.fill" } ?? "location.slash"
			let tint = item.map { statusTint(for: $0.state, at: now) } ?? .secondary

			HStack(spacing: 4) {
				Image(systemName: symbol)
				Text(title)

				if let item {
					Text(
						item.state == .onCampus ? "Arrived: " : "Left: "
					)
					.foregroundStyle(.secondary)

					Text(item.updatedAt, format: .dateTime.hour().minute())
						.foregroundStyle(.secondary)
				}
			}
			.font(.caption2)
			.foregroundStyle(tint)
		}
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
