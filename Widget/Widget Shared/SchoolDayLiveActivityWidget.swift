#if os(iOS)
	import ActivityKit
	import SwiftUI
	import WidgetKit

	struct SchoolDayLiveActivityWidget: Widget {
		var body: some WidgetConfiguration {
			ActivityConfiguration(for: SchoolDayActivityAttributes.self) { context in
				SchoolDayLiveActivityView(context: context)
					.widgetURL(URL(string: "timetable://timetable"))
			} dynamicIsland: { context in
				DynamicIsland {
					DynamicIslandExpandedRegion(.leading) {
						Image(systemName: context.state.symbol)
							.font(.title2)
							.foregroundStyle(context.state.color.swiftUIColor)
					}

					DynamicIslandExpandedRegion(.trailing) {
						SchoolDayActivityTimer(state: context.state)
							.font(.headline.monospacedDigit())
					}

					DynamicIslandExpandedRegion(.center) {
						Text(context.state.title)
							.font(.headline)
							.lineLimit(1)
					}

					DynamicIslandExpandedRegion(.bottom) {
						VStack(spacing: 6) {
							SchoolDayActivityProgress(state: context.state)
							if let nextText = context.state.nextText {
								Text(nextText)
									.font(.caption)
									.foregroundStyle(.secondary)
									.lineLimit(1)
							}
						}
					}
				} compactLeading: {
					Image(systemName: context.state.symbol)
						.foregroundStyle(context.state.color.swiftUIColor)
				} compactTrailing: {
					SchoolDayActivityTimer(state: context.state)
						.font(.caption2.monospacedDigit())
						.frame(maxWidth: 46)
				} minimal: {
					Image(systemName: context.state.symbol)
						.foregroundStyle(context.state.color.swiftUIColor)
				}
				.keylineTint(context.state.color.swiftUIColor)
				.widgetURL(URL(string: "timetable://timetable"))
			}
			.supplementalActivityFamilies([.small, .medium])
		}
	}

	private struct SchoolDayLiveActivityView: View {
		@Environment(\.activityFamily) private var activityFamily
		let context: ActivityViewContext<SchoolDayActivityAttributes>

		var body: some View {
			if activityFamily == .small {
				watchView
			} else {
				lockScreenView
			}
		}

		private var watchView: some View {
			VStack(alignment: .leading, spacing: 5) {
				HStack(spacing: 5) {
					Image(systemName: context.state.symbol)
						.foregroundStyle(context.state.color.swiftUIColor)
					Text(context.state.title)
						.font(.headline)
						.lineLimit(1)
				}

				if context.isStale {
					Label("Updating", systemImage: "arrow.trianglehead.2.clockwise")
						.font(.caption2)
						.foregroundStyle(.secondary)
				} else {
					SchoolDayActivityTimer(state: context.state)
						.font(.title3.monospacedDigit().bold())
					SchoolDayActivityProgress(state: context.state)
				}
			}
			.padding()
		}

		private var lockScreenView: some View {
			VStack(alignment: .leading, spacing: 9) {
				HStack(alignment: .firstTextBaseline) {
					Label(context.state.title, systemImage: context.state.symbol)
						.font(.title2.bold())
						.lineLimit(1)
					Spacer()
					SchoolDayActivityTimer(state: context.state)
						.font(.title2.monospacedDigit().bold())
				}

				if context.isStale {
					Label("Updating", systemImage: "arrow.trianglehead.2.clockwise")
						.font(.caption)
						.foregroundStyle(.secondary)
				} else {
					SchoolDayActivityProgress(state: context.state)
				}

				if let nextText = context.state.nextText {
					Text(nextText)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				} else if context.state.phase == .finished {
					Text("No more subjects")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
			.padding()
			.tint(context.state.color.swiftUIColor)
			.activityBackgroundTint(.black)
		}
	}

	private struct SchoolDayActivityTimer: View {
		let state: SchoolDayActivityAttributes.ContentState

		var body: some View {
			if let startDate = state.startDate, let endDate = state.endDate, startDate < endDate {
				Text(timerInterval: startDate ... endDate, countsDown: true)
			} else if state.phase == .finished {
				Text("Done")
			} else {
				Text("--:--")
			}
		}
	}

	private struct SchoolDayActivityProgress: View {
		let state: SchoolDayActivityAttributes.ContentState

		var body: some View {
			if let startDate = state.startDate, let endDate = state.endDate, startDate < endDate {
				ProgressView(timerInterval: startDate ... endDate, countsDown: false)
					.tint(state.color.swiftUIColor)
			}
		}
	}
#endif
