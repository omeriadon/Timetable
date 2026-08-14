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
				.background {
					if currentDayIndex == day {
						ZStack {
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(.primary.opacity(0.1))
								.strokeBorder(.primary, lineWidth: 2)
								.blur(radius: 5)
								.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(.primary.opacity(0.1))
								.strokeBorder(.primary, lineWidth: 2)
						}
						.allowsHitTesting(false)
					}
				}
			}
		}
		.foregroundStyle(.primary)
	}

	@ViewBuilder
	private func cell(day: Int, session: Int, subjectLookup: [Slot: Subject]) -> some View {
		let slot = Slot(day, session)
		let cell = SessionCellView(day, session, subjectLookup, selectedSlot)
			.contentShape(Rectangle())

		if case nil = onSelectSlot {
			cell
		} else {
			cell
				.accessibilityElement(children: .ignore)
				.accessibilityLabel(slotAccessibilityLabel(for: slot, subjectLookup: subjectLookup))
				.accessibilityValue(selectedSlot == slot ? "Selected" : "Not selected")
				.accessibilityAddTraits(.isButton)
				.accessibilityAction {
					select(slot, isAvailable: subjectLookup[slot] != nil)
				}
				.onTapGesture {
					select(
						slot,
						isAvailable: subjectLookup[slot] != nil
					)
				}
		}
	}

	private func slotAccessibilityLabel(for slot: Slot, subjectLookup: [Slot: Subject]) -> String {
		let day = TimetableLayout.shortDayLabels[slot.day]
		let session = TimetableLayout.sessions[slot.session]

		if let subject = subjectLookup[slot] {
			return "\(day), \(session), \(subject.id)"
		}

		if TimetableLayout.isBreakSession(index: slot.session) {
			return "\(day), \(session), break"
		}

		if TimetableLayout.isUnavailable(day: slot.day, session: slot.session) {
			return "\(day), \(session), unavailable"
		}

		return "\(day), \(session), free"
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
			.foregroundStyle(isBreakSession ? Color.secondary : Color.primary)
			.font(.callout)
	}
}
