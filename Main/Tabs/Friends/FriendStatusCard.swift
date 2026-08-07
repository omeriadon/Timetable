import Defaults
import SwiftUI

struct FriendStatusCard: View {
	let friend: FriendSummary
	@Default(.schoolCalendar) private var schoolCalendar

	private var displayName: String {
		friend.friend.displayName
	}

	var body: some View {
		TimelineView(.periodic(from: .now, by: 30)) { context in
			let scheduleStatus = FriendScheduleStatus(
				subjects: friend.timetable?.subjects ?? [],
				at: TimetableClock.adjusted(context.date),
				schoolCalendar: schoolCalendar
			)
			let locationStatus = FriendLocationStatus(
				item: friend.locationStatus
			)
			HStack(alignment: .center, spacing: 14) {
				FriendAvatar(profile: friend.friend)

				VStack(alignment: .leading, spacing: 5) {
					HStack {
						Text(displayName)
							.font(.title3.weight(.semibold))

						Spacer()

						Text(locationStatus.title)
							.fontWeight(.medium)
							.font(.caption)
							.padding(5)
							.glassEffect(
								.regular.tint(locationStatus.tint ?? nil).interactive(),
								in: Capsule()
							)
							.frame(maxHeight: .infinity, alignment: .topTrailing)
					}

					HStack(spacing: 6) {
						Image(systemName: scheduleStatus.symbol)
						Text(scheduleStatus.title)
					}
					.font(.body)
					.contentTransition(.numericText())

					Text(nextClassTitle(for: scheduleStatus))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.foregroundStyle(.black)
			.padding(10)
			.background {
				FriendPaperBackground(cornerRadius: 28)
			}
			.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
			.contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
			.animation(.bouncy, value: scheduleStatus.title)
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

private struct FriendLocationStatus {
	let title: String
	let tint: Color?

	init(item: LocationStatusItem?) {
		guard let item else {
			title = "Status unavailable"
			tint = nil
			return
		}

		switch item.state {
			case .onCampus:
				title = "On Campus"
				tint = .green
			case .offCampus:
				title = "Off Campus"
				tint = .blue
		}
	}
}

struct FriendAvatar: View {
	private let appearance: ProfileAppearance
	private let photo: ProfilePhotoMetadata?
	private let badges: [ProfileBadge]
	private let size: CGFloat

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
		size = 54
	}

	init(profile: FriendProfile, size: CGFloat = 54) {
		appearance = profile.appearance
			?? profile.appearanceData.flatMap { try? JSONDecoder().decode(ProfileAppearance.self, from: $0) }
			?? .default
		photo = profile.photo
		badges = profile.badges
		self.size = size
	}

	var body: some View {
		ProfilePicture(
			appearance: appearance,
			photo: photo,
			size: size,
			badges: badges,
			accessibilityName: "Profile picture"
		)
	}
}

private struct FriendScheduleStatus {
	let title: String
	let nextTitle: String
	let symbol: String
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
				tint = .blue
			case let .lesson(lesson):
				title = lesson.subject.id
				nextTitle = lesson.next.title
				symbol = lesson.subject.symbol
				tint = lesson.subject.colour.swiftUIColor
			case let .freePeriod(period):
				title = "Free Period"
				nextTitle = period.next.title
				symbol = "studentdesk"
				tint = .mint
			case let .recess(state):
				title = BreakType.recess.description
				nextTitle = state.next.title
				symbol = BreakType.recess.symbol
				tint = .orange
			case let .lunch(state):
				title = BreakType.lunch.description
				nextTitle = state.next.title
				symbol = BreakType.lunch.symbol
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
				tint = .secondary
			case .noTimetable:
				title = "No Timetable"
				nextTitle = "This friend has not uploaded a timetable."
				symbol = "calendar.badge.exclamationmark"
				tint = .secondary
		}
	}
}
