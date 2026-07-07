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
						.font(.system(size: 34))
						.foregroundStyle(context.state.color.swiftUIColor)
						.monospaced()
				}

				DynamicIslandExpandedRegion(.trailing) {
					ZStack {
						if let startDate = context.state.startDate,
						   let endDate = context.state.endDate,
						   startDate < endDate
						{
							ProgressView(timerInterval: startDate ... endDate, countsDown: false) {
								EmptyView()
							} currentValueLabel: {
								Text(timerInterval: startDate ... endDate, countsDown: true)
									.monospaced()
							}
							.progressViewStyle(.circular)
							.tint(context.state.color.swiftUIColor)
						} else {
							Text("Done")
						}
					}
				}

				DynamicIslandExpandedRegion(.bottom) {
					var isBreak: Bool {
						context.state.phase == .recess || context.state.phase == .lunch
					}

					VStack(alignment: .center, spacing: 6) {
						HStack {
							Spacer()
							Text(context.state.title)
							Spacer()
						}
						.padding(.top, isBreak ? 3 : 0)
						.font(.system(size: 28))
						.bold()
						.lineLimit(1)
						.monospaced()
						.foregroundStyle(isBreak ? .white : context.state.color.swiftUIColor)

						if let nextText = context.state.nextText {
							HStack(alignment: .lastTextBaseline) {
								Text("Next:")
									.foregroundStyle(.secondary)
									.font(.system(size: 13))

								Spacer()

								Text(nextText)
									.font(.system(size: 22))
									.lineLimit(1)
							}
							.padding(.horizontal, 10)
						}

						Spacer(minLength: 1)
					}

					.background {
						if context.state.phase == .recess || context.state.phase == .lunch {
							StaticIrregularGradient(
								colors: [.blue, .green, .mint, .cyan],
								background: .clear
							)
							.clipShape(RoundedRectangle(cornerRadius: 20))
						}
					}
					.monospaced()
				}
			} compactLeading: {
				Image(systemName: context.state.symbol)
					.foregroundStyle(context.state.color.swiftUIColor)
					.background {
						if context.state.phase == .recess || context.state.phase == .lunch {
							StaticIrregularGradient(
								colors: [.blue, .green, .mint, .cyan],
								background: .clear
							)
							.clipShape(.circle)
						}
					}

			} compactTrailing: {
				if let startDate = context.state.startDate,
				   let endDate = context.state.endDate,
				   startDate < endDate
				{
					ProgressView(timerInterval: startDate ... endDate, countsDown: false) {
						EmptyView()
					} currentValueLabel: {
						Text(timerInterval: startDate ... endDate, countsDown: true)
							.monospaced()
					}
					.progressViewStyle(.circular)
					.tint(context.state.color.swiftUIColor)
					.monospaced()

				} else {
					Text("Done")
				}
			} minimal: {
				if let startDate = context.state.startDate,
				   let endDate = context.state.endDate,
				   startDate < endDate
				{
					ProgressView(timerInterval: startDate ... endDate, countsDown: false) {
						EmptyView()
					} currentValueLabel: {
						Text(timerInterval: startDate ... endDate, countsDown: true)
							.monospaced()
					}
					.progressViewStyle(.circular)
					.tint(context.state.color.swiftUIColor)
					.monospaced()
				} else {
					Image(systemName: context.state.symbol)
						.foregroundStyle(context.state.color.swiftUIColor)
				}
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
		VStack(alignment: .leading, spacing: 0) {
			HStack(spacing: 4) {
				Image(systemName: context.state.symbol)
				Text(context.state.title)
					.lineLimit(1)
					.font(.system(size: 16, weight: .semibold, design: .monospaced))
			}

			if let startDate = context.state.startDate,
			   let endDate = context.state.endDate,
			   startDate < endDate
			{
				SchoolDayActivityTimer(state: context.state)
					.font(.system(size: 25, design: .monospaced))

			} else {
				Text("Done")
					.font(.system(size: 25, design: .monospaced))
			}

			Spacer(minLength: 1)

			if let nextText = context.state.nextText {
				HStack {
					Text("Next:")
						.font(.system(size: 18, design: .monospaced))
						.foregroundStyle(.secondary)

					Spacer()

					Text(nextText)
						.font(.system(size: 20, design: .monospaced))
				}
			} else {
				HStack {
					Spacer()
					Text("No more classes")
						.font(.system(size: 19, design: .monospaced))
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(.vertical, 5)
		.padding(.horizontal, 7)
		.monospaced()
	}

	private var lockScreenView: some View {
		VStack(alignment: .leading, spacing: 9) {
			HStack {
				Image(systemName: context.state.symbol)

				Text(context.state.title)
			}
			.font(.system(size: 22, weight: .bold))
			.lineLimit(1)

			if let startDate = context.state.startDate, let endDate = context.state.endDate, startDate < endDate {
				ProgressView(timerInterval: startDate ... endDate, countsDown: false) {
					EmptyView()
				} currentValueLabel: {
					HStack(alignment: .lastTextBaseline) {
						Text(timerInterval: startDate ... endDate, countsDown: true)
							.foregroundStyle(.white)
							.font(.system(size: 20))
							.monospaced()

						Spacer()
						Spacer()

						if let nextText = context.state.nextText {
							Text("Next:")
								.font(.system(size: 17))
								.foregroundStyle(.secondary)

							Spacer()

							Text(nextText)
								.font(.system(size: 22))
								.bold()
								.lineLimit(1)
								.foregroundStyle(.white)

						} else if context.state.phase == .finished {
							Text("No more subjects")
								.font(.system(size: 17, weight: .semibold))
								.foregroundStyle(.secondary)
						}
					}
				}
				.tint(.white)
				.progressViewStyle(.linear)

			} else if context.state.phase == .finished {
				Text("No more classes")
					.font(.system(size: 20))
					.foregroundStyle(.secondary)
			}
		}
		.monospaced()
		.padding([.horizontal])
		.padding(.vertical, 10)
		.tint(context.state.color.swiftUIColor)
		.activityBackgroundTint(context.state.color.swiftUIColor)
	}
}

private struct SchoolDayActivityTimer: View {
	let state: SchoolDayActivityAttributes.ContentState

	var body: some View {
		if let startDate = state.startDate, let endDate = state.endDate {
			Text(timerInterval: startDate ... endDate, pauseTime: startDate, countsDown: true, showsHours: false)
				.monospaced()
				.contentTransition(.numericText(countsDown: true))

		} else if state.phase == .finished {
			Text("Done")
				.monospaced()
		} else {
			Text("--:--")
				.monospaced()
		}
	}
}

private struct SchoolDayActivityProgress: View {
	let state: SchoolDayActivityAttributes.ContentState

	var body: some View {
		if let startDate = state.startDate, let endDate = state.endDate, startDate < endDate {
			ProgressView(timerInterval: startDate ... endDate, countsDown: false) {
				EmptyView()
			} currentValueLabel: {
				Text(timerInterval: startDate ... endDate, countsDown: true)
					.foregroundStyle(.white)
					.monospaced()
			}
			.tint(state.color.swiftUIColor)
			.progressViewStyle(.linear)

		} else if state.phase == .finished {
			Text("No more classes")
				.font(.system(size: 12))
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
