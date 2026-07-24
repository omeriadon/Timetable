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
				.overlay(alignment: .topTrailing) {
					if context.isStale {
						Text("Updating")
							.font(.caption2.bold())
							.padding(5)
							.background(.black.opacity(0.35), in: Capsule())
					}
				}
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
								Text(timerInterval: startDate ... endDate, countsDown: true, showsHours: false)
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
						.font(.system(size: 22))
						.bold()
						.lineLimit(1)
						.monospaced()
						.foregroundStyle(isBreak ? .white : context.state.color.swiftUIColor)

						if let nextText = context.state.nextText {
							HStack(alignment: .lastTextBaseline) {
								Text(nextText == "Last Period" ? "Last Period" : "Next: \(nextText)")
									.font(.system(size: 19))
									.bold()
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
						Text(timerInterval: startDate ... endDate, countsDown: true, showsHours: false)
							.font(.system(size: 12, design: .monospaced))
							.fontDesign(.monospaced)
							.monospacedDigit()
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
					}
					.progressViewStyle(.circular)
					.tint(context.state.color.swiftUIColor)
					.frame(width: 24, height: 24)
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
		Group {
			if activityFamily == .small {
				watchView
			} else {
				lockScreenView
			}
		}
		.dynamicTypeSize(.medium)
	}

	private var watchView: some View {
		VStack(alignment: .leading, spacing: 0) {
			HStack(spacing: 4) {
				Image(systemName: context.state.symbol)
					.font(.system(size: 16, weight: .semibold))

				Text(context.state.title)
					.lineLimit(1)
					.font(.system(size: 16, weight: .semibold, design: .monospaced))
			}

			Spacer(minLength: 1)

			if let startDate = context.state.startDate,
			   let endDate = context.state.endDate,
			   startDate < endDate
			{
				Text(timerInterval: startDate ... endDate, countsDown: true, showsHours: false)
					.font(.system(size: 25, weight: .regular, design: .monospaced))
					.fontDesign(.monospaced)
					.monospacedDigit()
			} else {
				Text("Done")
					.font(.system(size: 25, weight: .regular, design: .monospaced))
			}

			Spacer(minLength: 1)

			if let nextText = context.state.nextText {
				HStack {
					Text(nextText == "Last Period" ? "Last Period" : "Next: \(nextText)")
						.font(.system(size: 20, weight: .regular, design: .monospaced))
						.fontDesign(.monospaced)
						.lineLimit(1)
				}
			} else {
				HStack {
					Spacer()

					Text("No more classes")
						.font(.system(size: 19, weight: .regular, design: .monospaced))
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(.vertical, 5)
		.padding(.top, 2)
		.padding(.horizontal, 7)
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
				ProgressView(timerInterval: startDate ... endDate, countsDown: false)
					.tint(.white)
					.progressViewStyle(.linear)

				HStack(alignment: .lastTextBaseline) {
					Text(timerInterval: startDate ... endDate, countsDown: true, showsHours: false)
						.foregroundStyle(.white)
						.font(.system(size: 20, design: .monospaced))
						.fontDesign(.monospaced)
						.monospacedDigit()
						.fixedSize(horizontal: true, vertical: false)

					if let nextText = context.state.nextText {
						Spacer()
							.frame(width: 40)

						Text(nextText == "Last Period" ? "Last Period" : "Next: \(nextText)")
							.font(.system(size: 16, design: .monospaced))
							.fontDesign(.monospaced)
							.lineLimit(1)
							.truncationMode(.tail)
							.frame(maxWidth: .infinity, alignment: .trailing)
							.foregroundStyle(.secondary)
					}
				}

			} else if context.state.phase == .finished {
				Text("No more classes")
					.font(.system(size: 20))
					.foregroundStyle(.secondary)
			} else {
				Text("No more classes today")
					.font(.system(size: 17, weight: .semibold))
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
