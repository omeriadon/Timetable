import Defaults
import SwiftUI

struct TimetableWeekGrid: View {
	let subjects: [Subject]
	let selectedSlot: Slot?
	let onSelectSlot: ((Slot?) -> Void)?
	@Default(.accountSettings) private var accountSettings

	var body: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: subjects)

		HStack(spacing: 4) {
			VStack(spacing: 4) {
				Text("")

				ForEach(TimetableLayout.sessions, id: \.self) { session in
					sessionLabel(for: session)
				}
			}
			.frame(width: 15)

			ForEach(0 ..< 5) { day in
				VStack(spacing: 4) {
					Text(TimetableLayout.shortDayLabels[day])
						.padding(.top, 3)

					ForEach(0 ..< 8) { session in
						cell(day: day, session: session, subjectLookup: subjectLookup)
					}
				}
				.overlay {
					if accountSettings.highlightsCurrentDay, currentDayIndex == day {
						ZStack {
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(.white.opacity(0.1))
								.strokeBorder(.white, lineWidth: 2)
								.blur(radius: 5)
								.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(.white.opacity(0.1))
								.strokeBorder(.white, lineWidth: 2)
						}
						.allowsHitTesting(false)
					}
				}
			}
		}
		.foregroundStyle(.white)
	}

	@ViewBuilder
	private func cell(day: Int, session: Int, subjectLookup: [Slot: Subject]) -> some View {
		let cell = SessionCellView(day, session, subjectLookup, selectedSlot)
			.contentShape(Rectangle())

		if case nil = onSelectSlot {
			cell
		} else {
			cell
				.onTapGesture {
					select(
						Slot(day, session),
						isAvailable: subjectLookup[Slot(day, session)] != nil
					)
				}
		}
	}

	private func select(_ slot: Slot, isAvailable: Bool) {
		guard let onSelectSlot, isAvailable else {
			return
		}

		withAnimation(.snappy(duration: 0.3)) {
			onSelectSlot(selectedSlot == slot ? nil : slot)
		}
	}

	private var currentDayIndex: Int? {
		let weekday = Calendar.current.component(.weekday, from: TimetableClock.now)
		guard (2 ... 6).contains(weekday) else {
			return nil
		}
		return weekday - 2
	}

	private func sessionLabel(for session: String) -> some View {
		let isBreakSession = TimetableLayout.isBreakSession(label: session)

		return Text(session)
			.frame(height: isBreakSession ? TimetableLayout.breakCellHeight : TimetableLayout.sessionCellHeight)
			.foregroundStyle(isBreakSession ? Color.clear : Color.white)
	}
}
