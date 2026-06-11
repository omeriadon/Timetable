//
//  TimetableView.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI

struct TimetableView: View {
	@ObservedObject var watchSync: PhoneWatchSyncBridge

	@Default(.timetable) var classes
	@Default(.receivedTimetables) var receivedTimetables
	@Default(.userDisplayName) var userDisplayName
	@Default(.displayMode) var displayMode

	@State private var selectedTimetable: ReceivedTimetable?
	@State private var showTimetableComparison = false
	@State private var selectedSlot: Slot? = nil

	@Binding var syncStatus: SyncMode

	init(
		watchSync: PhoneWatchSyncBridge,
		syncStatus: Binding<SyncMode>,
		startComparisonOpen: Bool = false
	) {
		self.watchSync = watchSync
		self._syncStatus = syncStatus
		self._showTimetableComparison = State(initialValue: startComparisonOpen)
	}

	var currentTimetableTitle: String {
		if let timetable = selectedTimetable {
			return "\(timetable.sender)'s Timetable"
		}
		return "Timetable"
	}

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: selectedTimetable?.classes ?? classes)

		NavigationStack {
			VStack {
				ScrollView {
					TimetableComparison(selectedSlot: selectedSlot)
						.opacity(selectedSlot == nil ? 0 : 1)
						.blur(radius: selectedSlot == nil ? 20 : 0)
						.allowsHitTesting(selectedSlot != nil)
						.animation(.snappy(duration: 0.3), value: selectedSlot)
				}
				.scrollBounceBehavior(.basedOnSize)
				.scrollIndicators(.visible)
				.scrollIndicatorsFlash(onAppear: true)
				.safeAreaBar(edge: .top, alignment: .center, spacing: 10) {
					HStack(spacing: 4) {
						VStack(spacing: 4) {
							Text("")

							ForEach(TimetableLayout.sessions, id: \.self) { session in
								sessionLabel(for: session)
							}
						}
						.frame(width: 15)

						mainContent(classLookup: classLookup)
					}
					.padding(.bottom, 10)
				}
				.scrollEdgeEffectStyle(.soft, for: .bottom)
				.scrollEdgeEffectStyle(.hard, for: .top)
			}
			.onAppear {
				watchSync.activateIfNeeded()
				watchSync.updateLatestClasses(classes)
			}
			.onChange(of: classes) { _, newValue in
				watchSync.updateLatestClasses(newValue)
			}
			.onChange(of: watchSync.lastError) { _, newValue in
				guard let newValue else { return }
				print("[iOS] Surface error icon: \(newValue)")
				syncStatus = .error
				Task {
					try? await Task.sleep(nanoseconds: 1_000_000_000)
					await MainActor.run {
						syncStatus = .normal
					}
				}
				watchSync.lastError = nil
			}
		}
		.padding(.trailing, 2)
	}

	private func findCurrentClass(in timetable: [Class]) -> Class? {
		let today = Date()
		let weekday = Calendar.current.component(.weekday, from: today)
		let dayIndex = (weekday + 5) % 7

		guard dayIndex < 5 else { return nil }

		let hour = Calendar.current.component(.hour, from: today)
		let minute = Calendar.current.component(.minute, from: today)
		let timeInMinutes = hour * 60 + minute

		let periodSchedule = [
			(8, 50, 9, 48), // Period 1
			(9, 48, 10, 46), // Period 2
			(11, 8, 12, 6), // Period 3
			(12, 6, 13, 4), // Period 4
			(13, 34, 14, 32), // Period 5
			(14, 32, 15, 30), // Period 6
		]

		for (sessionIndex, (startH, startM, endH, endM)) in periodSchedule.enumerated() {
			let startMinutes = startH * 60 + startM
			let endMinutes = endH * 60 + endM

			if timeInMinutes >= startMinutes, timeInMinutes < endMinutes {
				let classLookup = TimetableLayout.classLookup(for: timetable)
				return classLookup[Slot(dayIndex, sessionIndex)]
			}
		}
		return nil
	}

	func mainContent(classLookup: [Slot: Class]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 4) {
				Text(TimetableLayout.shortDayLabels[day])
				ForEach(0 ..< 8) { session in
					Button {
						if selectedSlot == Slot(day, session) {
							selectedSlot = nil
						} else if let c = classLookup[Slot(day, session)] {
							if !receivedTimetables.isEmpty {
								selectedSlot = Slot(day, session)
							}
						}
					} label: {
						sessionCell(day, session, classLookup: classLookup)
							.contentShape(Rectangle())
					}
					.buttonStyle(.plain)
				}
			}
		}
	}

	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		Group {
			// break
			if TimetableLayout.isBreakSession(index: session) {
				rectangle(.gray.opacity(0.25), true)
					.frame(height: 20)

				// unavailable
			} else if TimetableLayout.isUnavailable(day: day, session: session) {
				rectangle(.clear, true)
					.frame(height: 60)

				// normal
			} else if let c = classLookup[Slot(day, session)] {
				rectangle(
					c.colour.swiftUIColor.opacity(0.8),
					selected: Slot(day, session) == selectedSlot
				) {
					Image(systemName: c.symbol)
					Spacer(minLength: 0)
					Text(c.id)
						.lineLimit(2)
						.fixedSize(horizontal: false, vertical: true)
						.font(.footnote.scaled(by: 0.9))
				}
				.frame(height: 60)

				// idk
			} else {
				RoundedRectangle(cornerRadius: 10)
					.fill(.white.opacity(0.05))
					.frame(height: 60)
			}
		}
		.foregroundStyle(.white)
	}

	func sessionLabel(for session: String) -> some View {
		let isBreakSession = TimetableLayout.isBreakSession(label: session)

		return Text(session)
			.frame(height: isBreakSession ? 20 : 60)
			.foregroundStyle(isBreakSession ? Color.secondary : Color.primary)
	}

	func editableSlot(fromDay day: Int, session: Int) -> EditableSlot? {
		guard
			let period = TimetableLayout.period(forSession: session),
			TimetableLayout.canUse(period: period, on: day)
		else { return nil }

		return EditableSlot(day: day, period: period)
	}
}

#Preview {
	@Previewable @State var syncMode: SyncMode = .normal

	@Previewable @State var showTimetableComparison = true

	TimetableView(
		watchSync: PhoneWatchSyncBridge(),
		syncStatus: $syncMode,
		startComparisonOpen: false
	)
}
