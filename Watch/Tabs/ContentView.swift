//
//   ContentView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct ContentView: View {
	@State private var selectedDay = 0
	@State private var isLoading = false
	@State private var showSyncErrorIcon = false

	@Default(.timetable) var subjects
	@Default(.accountSettings) private var accountSettings

	var body: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: subjects)

		NavigationStack {
			ZStack {
				if subjects.isEmpty {
					VStack {
						Spacer()
						ContentUnavailableView("No Timetable", systemImage: "calendar.badge.exclamationmark", description: Text("Sync your timetable from iPhone to view it here."))
						Spacer()
					}
					.transition(.blurReplace)
				} else {
					VStack {
						HStack(spacing: 2) {
							VStack(spacing: 2) {
								Text("")
									.frame(height: 15)
									.font(.footnote)

								ForEach(Array(TimetableLayout.sessions.enumerated()), id: \.offset) { index, session in
									if TimetableLayout.isBreakSession(index: index) {
										Color.clear.frame(height: TimetableLayout.breakCellHeight)
									} else {
										Text(session)
											.font(.footnote)
											.frame(height: TimetableLayout.sessionCellHeight)
									}
								}
							}
							.frame(width: 7)

							mainContent(subjectLookup: subjectLookup)
						}
						Spacer()
					}
					.transition(.blurReplace)
				}
			}
		}
		.animation(.easeInOut, value: subjects.isEmpty)
		.padding(.trailing, 8)
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
		.dynamicTypeSize(.xSmall)
	}

	func mainContent(subjectLookup: [Slot: Subject]) -> some View {
		GlassEffectContainer(spacing: 2) {
			HStack(spacing: 2) {
				ForEach(0 ..< 5) { day in
					VStack(spacing: 2) {
						Text(TimetableLayout.shortDayLabels[day])
							.font(.footnote.scaled(by: 0.8))
							.frame(height: 15)
						ForEach(0 ..< 8) { session in
							sessionCell(day, session, subjectLookup: subjectLookup)
						}
					}
					.background {
						if accountSettings.highlightsCurrentDay, currentDayIndex == day {
							RoundedRectangle(cornerRadius: 5)
								.fill(.white.opacity(0.1))
								.strokeBorder(.white, lineWidth: 1, antialiased: true)
						}
					}
				}
			}
		}
		.drawingGroup(opaque: false)
	}

	private var currentDayIndex: Int? {
		let weekday = Calendar.current.component(.weekday, from: TimetableClock.now)
		guard (2 ... 6).contains(weekday) else { return nil }
		return weekday - 2
	}

	func sessionCell(_ day: Int, _ session: Int, subjectLookup: [Slot: Subject]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				// recess and lunch
				Color.clear.frame(height: TimetableLayout.breakCellHeight)
			} else {
				// early finish days
				if TimetableLayout.isUnavailable(day: day, session: session) {
					rectangle(.clear, true)
						.frame(height: TimetableLayout.sessionCellHeight)

				} else {
					// actual session
					if let c = subjectLookup[Slot(day, session)] {
						rectangle(
							c.colour.swiftUIColor.opacity(0.8)
						) {
							Image(systemName: c.symbol)
								.imageScale(.small)
								.font(.footnote.scaled(by: 0.7))
							Spacer(minLength: 0)
							Text(c.id)
								.lineLimit(2)
								.fixedSize(horizontal: false, vertical: true)
								.font(.footnote.scaled(by: 0.5))
						}
						.frame(height: TimetableLayout.sessionCellHeight)

					} else {
						// empty periods
						RoundedRectangle(cornerRadius: 5)
							.fill(.gray).opacity(0.5)
							.frame(height: TimetableLayout.sessionCellHeight)
					}
				}
			}
		}
		.foregroundStyle(.white)
	}

	@MainActor
	func flashSyncErrorIcon() {
		withAnimation(.snappy) { showSyncErrorIcon = true }
		Task {
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			await MainActor.run {
				withAnimation(.snappy) { showSyncErrorIcon = false }
			}
		}
	}
}

#Preview {
	ContentView()
}
