//
//  SchoolDayLiveActivityWidget.swift
//  Widget
//
//  Created by Adon Omeri on 5/7/2026.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct SchoolDayLiveActivityWidget: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: SchoolDayActivityAttributes.self) { context in
			SchoolDayLiveActivityView(context: context)
				.activityBackgroundTint(context.state.color.swiftUIColor)
				.activitySystemActionForegroundColor(.white)
				.contentMargins(.vertical, 0, for: .automatic)
				.widgetURL(URL(string: "timetable://timetable"))

		} dynamicIsland: { context in
			DynamicIsland {
				DynamicIslandExpandedRegion(.leading) {
					Image(systemName: context.state.symbol)
						.font(.largeTitle)
						.foregroundStyle(context.state.color.swiftUIColor)
						.monospaced()
				}

				DynamicIslandExpandedRegion(.trailing) {
					SchoolDayActivityTimer(state: context.state)
						.font(.system(size: 100))
						.monospaced()
						.bold()
						.minimumScaleFactor(0.1)
						.frame(maxWidth: 140, alignment: .trailing)
				}

				DynamicIslandExpandedRegion(.bottom) {
					ZStack {
//						if context.state.phase == .lunch || context.state.phase == .recess {
//							Color.blue
//								.ignoresSafeArea()
//								.clipShape(ContainerRelativeShape())
//						}

						VStack(alignment: .center, spacing: 6) {
							Text(context.state.title)
								.font(.system(size: 28))
								.bold()
								.lineLimit(1)
								.monospaced()

							SchoolDayActivityProgress(state: context.state)

							if let nextText = context.state.nextText {
								HStack {
									Text("Next:")
										.foregroundStyle(.secondary)
										.font(.system(size: 13))

									Spacer()

									Text(nextText)
										.font(.system(size: 22))
										.lineLimit(1)
								}
								.padding(.horizontal)
							}
						}
					}
					.monospaced()
				}
			} compactLeading: {
				Image(systemName: context.state.symbol)
					.foregroundStyle(context.state.color.swiftUIColor)
					.monospaced()

			} compactTrailing: {
				SchoolDayActivityTimer(state: context.state)
					.font(.system(size: 16))
					.frame(maxWidth: 51)
			} minimal: {
				SchoolDayActivityTimer(state: context.state)
					.font(.system(size: 12))
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
		VStack(alignment: .leading) {
			HStack(spacing: 5) {
				Image(systemName: context.state.symbol)
					.monospaced()

				Text(context.state.title)
					.font(.headline)
					.monospaced()
					.lineLimit(1)
			}

			Spacer()

			if context.isStale {
				Label("Updating", systemImage: "arrow.trianglehead.2.clockwise")
					.font(.caption2)
					.foregroundStyle(.secondary)
			} else {
				SchoolDayActivityTimer(state: context.state)
					.font(.system(size: 17, design: .monospaced))
					.bold()
					.monospaced()

				Spacer()

				SchoolDayActivityProgress(state: context.state)
			}
		}
		.padding(.vertical, 5)
		.padding(.horizontal, 7)
		.monospaced()
	}

	private var lockScreenView: some View {
		VStack(alignment: .leading, spacing: 9) {
			HStack(alignment: .center) {
				HStack {
					Image(systemName: context.state.symbol)

					Text(context.state.title)
				}
				.font(.title2.bold())
				.lineLimit(1)

				Spacer()

				SchoolDayActivityTimer(state: context.state)
					.font(.title)
					.frame(maxWidth: 90)
			}

			if context.isStale {
				Label("Updating", systemImage: "arrow.trianglehead.2.clockwise")
					.font(.caption)
					.foregroundStyle(.secondary)
			} else {
				SchoolDayActivityProgress(state: context.state)
			}

			if let nextText = context.state.nextText {
				HStack(alignment: .firstTextBaseline) {
					Text("Next:")
						.foregroundStyle(.secondary)

					Spacer()

					Text(nextText)
						.font(.title2)
						.lineLimit(1)
				}
			} else if context.state.phase == .finished {
				Text("No more subjects")
					.font(.headline)
					.foregroundStyle(.secondary)
			}
		}
		.monospaced()
		.padding()
		.tint(context.state.color.swiftUIColor)
		.activityBackgroundTint(context.state.color.swiftUIColor)
	}
}

private struct SchoolDayActivityTimer: View {
	let state: SchoolDayActivityAttributes.ContentState

	var body: some View {
		if let endDate = state.endDate {
			Text(endDate, style: .timer)
				.contentTransition(.numericText(countsDown: true))
				.monospaced()
				.transition(.blurReplace)

		} else if state.phase == .finished {
			Text("Done")
				.monospaced()
				.transition(.blurReplace)
		} else {
			Text("--:--")
				.monospaced()
				.transition(.blurReplace)
		}
	}
}

private struct SchoolDayActivityProgress: View {
	let state: SchoolDayActivityAttributes.ContentState

	@Environment(\.activityFamily) var activityFamily

	var body: some View {
		if let startDate = state.startDate, let endDate = state.endDate, startDate < endDate {
			ProgressView(timerInterval: startDate ... endDate, countsDown: false)
				.labelsHidden()
				.tint(activityFamily == .small ? state.color.swiftUIColor : .white)
//				.tint(.white)

		} else if state.phase == .finished {
			Text("No more classes")
				.font(.caption)
				.foregroundStyle(.secondary)
		}
	}
}

// MARK: - Previews

extension SchoolDayActivityAttributes {
	static let preview = SchoolDayActivityAttributes(
		activityKey: "preview-school-day",
		schoolDate: "2026-07-04"
	)
}

extension SchoolDayActivityAttributes.ContentState {
	static let lessonPreview = Self(
		phase: .lesson,
		title: "Chemistry",
		symbol: "flask",
		color: RGBAColor(red: 0, green: 1, blue: 0, alpha: 1),
		nextText: "Methods",
		startDate: .now,
		endDate: .now.addingTimeInterval(48 * 60)
	)

	static let recessPreview = Self(
		phase: .recess,
		title: "Recess",
		symbol: "cup.and.saucer",
		color: RGBAColor(red: 1, green: 0.6, blue: 0, alpha: 1),
		nextText: "Physics",
		startDate: .now,
		endDate: .now.addingTimeInterval(18 * 60)
	)

	static let finishedPreview = Self(
		phase: .finished,
		title: "Finished",
		symbol: "checkmark.circle",
		color: RGBAColor(red: 0, green: 0.8, blue: 1, alpha: 1),
		nextText: nil,
		startDate: nil,
		endDate: nil
	)
}

#Preview("Lock Screen", as: .content, using: SchoolDayActivityAttributes.preview) {
	SchoolDayLiveActivityWidget()
} contentStates: {
	SchoolDayActivityAttributes.ContentState.lessonPreview
	SchoolDayActivityAttributes.ContentState.recessPreview
	SchoolDayActivityAttributes.ContentState.finishedPreview
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: SchoolDayActivityAttributes.preview) {
	SchoolDayLiveActivityWidget()
} contentStates: {
	SchoolDayActivityAttributes.ContentState.lessonPreview
	SchoolDayActivityAttributes.ContentState.recessPreview
	SchoolDayActivityAttributes.ContentState.finishedPreview
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: SchoolDayActivityAttributes.preview) {
	SchoolDayLiveActivityWidget()
} contentStates: {
	SchoolDayActivityAttributes.ContentState.lessonPreview
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: SchoolDayActivityAttributes.preview) {
	SchoolDayLiveActivityWidget()
} contentStates: {
	SchoolDayActivityAttributes.ContentState.lessonPreview
}
