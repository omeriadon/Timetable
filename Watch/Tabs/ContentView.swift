//
//  ContentView.swift
//  Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import Defaults
import SwiftUI
import WatchConnectivity
import WidgetKit

struct ContentView: View {
	@State private var syncStore = WatchTimetableSyncStore()

	@State private var selectedDay = 0
	@State private var isLoading = false
	@State private var showSyncErrorIcon = false

	@Default(.timetable) var subjects

	var body: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: subjects)

		NavigationStack {
			VStack {
				HStack(spacing: 2) {
					VStack(spacing: 2) {
						Text("")
							.frame(height: 15)
							.font(.footnote)

						ForEach(Array(TimetableLayout.sessions.enumerated()), id: \.offset) { index, session in
							if TimetableLayout.isBreakSession(index: index) {
								Text(session)
									.font(.footnote.scaled(by: 0.7))
									.foregroundStyle(.secondary)
									.frame(height: 2)
							} else {
								Text(session)
									.font(.footnote)
									.frame(height: 25)
							}
						}
					}
					.frame(width: 7)

					mainContent(subjectLookup: subjectLookup)
				}
				Spacer()
			}
		}
		.padding(.trailing, 8)
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
		.onAppear {
			Print("[Watch] ContentView appeared")
			syncStore.activateIfNeeded()
		}
		.onChange(of: syncStore.alertMessage) { _, newValue in
			guard let newValue else { return }
			Print("[Watch] Surface error icon: \(newValue)")
			flashSyncErrorIcon()
			syncStore.alertMessage = nil
		}
	}

	func mainContent(subjectLookup: [Slot: Subject]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 2) {
				Text(TimetableLayout.shortDayLabels[day])
					.font(.footnote.scaled(by: 0.8))
					.frame(height: 15)
				ForEach(0 ..< 8) { session in
					sessionCell(day, session, subjectLookup: subjectLookup)
				}
			}
		}
	}

	func sessionCell(_ day: Int, _ session: Int, subjectLookup: [Slot: Subject]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				// recess and lunch
				rectangle(.clear, true)
					.frame(height: 2)
			} else {
				// early finish days
				if TimetableLayout.isUnavailable(day: day, session: session) {
					rectangle(.clear, true)
						.frame(height: 25)

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
						.frame(height: 25)

					} else {
						// empty periods
						RoundedRectangle(cornerRadius: 5)
							.frame(height: 25)
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
