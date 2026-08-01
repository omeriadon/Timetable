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

					Text(status.title)
						.font(.body)
						.contentTransition(.numericText())
					Text(nextClassTitle(for: status))
						.font(.callout)
						.foregroundStyle(.secondary)
				}
			}
			.foregroundStyle(.black)
			.padding(18)
			.background {
				FriendPaperBackground(cornerRadius: 28)
			}
			.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
			.contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
			.animation(.bouncy, value: status.title)
		}
	}

	private func nextClassTitle(for status: FriendScheduleStatus) -> String {
		if status.nextTitle.hasPrefix("Next:") || status.nextTitle == "No upcoming classes" {
			status.nextTitle
		} else {
			"Next: \(status.nextTitle)"
		}
	}
}

struct FriendAvatar: View {
	private let appearance: ProfileAppearance
	private let photo: ProfilePhotoMetadata?
	private let badges: [ProfileBadge]

	init(symbol: String) {
		appearance = ProfileAppearance(
			contentKind: .emoji,
			monogram: "",
			emoji: symbol == "person.fill" ? "👤" : "✨",
			fontDesign: .rounded,
			fontWeight: .semibold,
			colours: ProfileAppearance.default.colours,
			speed: 0,
			noise: 0
		)
		photo = nil
		badges = []
	}

	init(profile: FriendProfile) {
		appearance = profile.appearance
			?? profile.appearanceData.flatMap { try? JSONDecoder().decode(ProfileAppearance.self, from: $0) }
			?? .default
		photo = profile.photo
		badges = profile.badges
	}

	var body: some View {
		ProfilePicture(
			appearance: appearance,
			photo: photo,
			size: 54,
			badges: badges,
			accessibilityName: "Profile picture"
		)
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
			calendar: SchoolCalendarProjection.perthCalendar,
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
				if let next = SchoolStateEngine.nextScheduledSubject(
					after: date,
					subjects: subjects,
					calendar: SchoolCalendarProjection.perthCalendar,
					schoolCalendar: schoolCalendar
				) {
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
