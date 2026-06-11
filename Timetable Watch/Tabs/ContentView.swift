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
	@State private var displayModeConfirmation: String?

	@Default(.timetable) var classes
	@Default(.displayMode) var displayMode

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)

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

					mainContent(classLookup: classLookup)
				}
				Spacer()
			}
		}
		.padding(.trailing, 10)
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
		.overlay(alignment: .center) {
			if let mode = displayModeConfirmation {
				VStack(spacing: 8) {
					Label(mode, systemImage: mode == "Symbols" ? "square.grid.2x2" : "text.alignleft")
						.font(.headline)
				}
				.padding(.horizontal, 24)
				.padding(.vertical, 14)
				.glassEffect(
					.regular.tint(.blue),
					in: RoundedRectangle(cornerRadius: 12)
				)
				.transition(.opacity.combined(with: .scale(scale: 0.9)))
			}
		}
		.onAppear {
			print("[Watch] ContentView appeared")
			syncStore.activateIfNeeded()
		}
		.onChange(of: syncStore.alertMessage) { _, newValue in
			guard let newValue else { return }
			print("[Watch] Surface error icon: \(newValue)")
			flashSyncErrorIcon()
			syncStore.alertMessage = nil
		}
		.onChange(of: displayMode) { _, newMode in
			displayModeConfirmation = newMode == .symbolsOnly ? "Symbols" : "Text"
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
				displayModeConfirmation = nil
			}
		}
	}

	func mainContent(classLookup: [Slot: Class]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 2) {
				Text(TimetableLayout.shortDayLabels[day])
					.font(.footnote.scaled(by: 0.8))
					.frame(height: 15)
				ForEach(0 ..< 8) { session in
					sessionCell(day, session, classLookup: classLookup)
				}
			}
		}
	}

	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				// recess and lunch
				rectangle(.gray.opacity(0.25), true)
					.frame(height: 2)
			} else {
				// early finish days
				if TimetableLayout.isUnavailable(day: day, session: session) {
					rectangle(.clear, true)
						.frame(height: 25)

				} else {
					// actual session
					if let c = classLookup[Slot(day, session)] {
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
							.fill(.white.opacity(0.05))
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

	func dayView(_ day: Int) -> some View {
		let classLookup = TimetableLayout.classLookup(for: classes)

		return ScrollView(.vertical, showsIndicators: false) {
			VStack(spacing: 4) {
				ForEach(0 ..< 8, id: \.self) { session in
					sessionCell(day, session, classLookup: classLookup)
				}
			}
			.padding(.horizontal, 4)
			.padding(.vertical, 6)
		}
	}
}

#Preview {
	ContentView()
}
