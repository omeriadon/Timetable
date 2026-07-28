import Defaults
import SwiftUI

struct FriendStatusCard: View {
	let friend: FriendSummary
	@Default(.schoolCalendar) private var schoolCalendar

	var body: some View {
		TimelineView(.periodic(from: .now, by: 30)) { context in
			let status = FriendScheduleStatus(subjects: friend.timetable?.subjects ?? [], at: TimetableClock.adjusted(context.date), schoolCalendar: schoolCalendar)
			HStack(alignment: .center, spacing: 14) {
				FriendAvatar(profile: friend.friend)

				VStack(alignment: .leading, spacing: 5) {
					HStack {
						Text(friend.friend.displayName)
							.font(.title3.weight(.semibold))
						Spacer()
						Label(status.availability, systemImage: status.symbol)
							.font(.caption.weight(.medium))
							.foregroundStyle(status.tint)
					}

					Text("Now: \(status.title)")
						.font(.body)
						.contentTransition(.numericText())
					Text(status.nextTitle)
						.font(.callout)
						.foregroundStyle(.secondary)
				}

				Image(systemName: "chevron.right")
					.font(.headline)
					.foregroundStyle(.secondary)
			}
			.padding(18)
			.frame(minHeight: 132)
			.background(Image("paper").resizable().scaledToFill())
			.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
			.contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
			.animation(.bouncy, value: status.title)
		}
	}
}

struct FriendAvatar: View {
	private let appearance: ProfileAppearance

	init(symbol: String) {
		appearance = ProfileAppearance(
			usesMonogram: false,
			monogram: "",
			symbol: symbol,
			font: "rounded",
			colours: ProfileAppearance.default.colours,
			speed: 0,
			noise: 0
		)
	}

	init(profile: FriendProfile) {
		appearance = profile.appearanceData.flatMap { try? JSONDecoder().decode(ProfileAppearance.self, from: $0) } ?? .default
	}

	var body: some View {
		ZStack {
			LinearGradient(
				colors: appearance.colours.map(\.swiftUIColor),
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			if appearance.usesMonogram, !appearance.monogram.isEmpty {
				Text(appearance.monogram)
					.font(.system(size: 20, weight: .bold, design: fontDesign))
					.foregroundStyle(.white)
			} else {
				Image(systemName: appearance.symbol)
					.font(.title2)
					.foregroundStyle(.white)
			}
		}
		.frame(width: 54, height: 54)
		.clipShape(Circle())
		.accessibilityHidden(true)
	}

	private var fontDesign: Font.Design {
		switch appearance.font {
			case "serif": .serif
			case "monospaced": .monospaced
			case "rounded": .rounded
			default: .default
		}
	}
}

private struct FriendScheduleStatus {
	let title: String
	let nextTitle: String
	let symbol: String
	let availability: String
	let tint: Color

	init(subjects: [Subject], at date: Date, schoolCalendar: SchoolCalendarProjection) {
		let state = SchoolStateEngine.calculate(
			at: date,
			subjects: subjects,
			calendar: .perthCalendar,
			schoolCalendar: schoolCalendar
		)
		switch state {
			case let .beforeSchool(next):
				title = "Before School"
				nextTitle = "Next: \(next.subject.id)"
				symbol = "clock"
				availability = "Before school"
				tint = .blue
			case let .lesson(lesson):
				title = lesson.subject.id
				nextTitle = lesson.next.title
				symbol = lesson.subject.symbol
				availability = "In class"
				tint = lesson.subject.colour.swiftUIColor
			case let .freePeriod(period):
				title = "Free Period"
				nextTitle = period.next.title
				symbol = "studentdesk"
				availability = "Free"
				tint = .mint
			case let .recess(state):
				title = BreakType.recess.description
				nextTitle = state.next.title
				symbol = BreakType.recess.symbol
				availability = "On break"
				tint = .orange
			case let .lunch(state):
				title = BreakType.lunch.description
				nextTitle = state.next.title
				symbol = BreakType.lunch.symbol
				availability = "On break"
				tint = .orange
			case .afterSchool, .weekend:
				title = "School's Out"
				if let next = SchoolStateEngine.nextScheduledSubject(after: date, subjects: subjects, calendar: .perthCalendar, schoolCalendar: schoolCalendar) {
					nextTitle = "Next: \(next.subject.id)"
				} else {
					nextTitle = "No upcoming classes"
				}
				symbol = "house.fill"
				availability = "Offline"
				tint = .secondary
			case .noTimetable:
				title = "No Timetable"
				nextTitle = "This friend has not uploaded a timetable."
				symbol = "calendar.badge.exclamationmark"
				availability = "Unavailable"
				tint = .secondary
		}
	}
}
