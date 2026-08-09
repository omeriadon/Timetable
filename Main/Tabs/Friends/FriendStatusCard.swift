import Defaults
import SwiftUI

enum FriendStatusCardStyle: Equatable {
	case list
	case detail
}

struct FriendStatusCard: View {
	let friend: FriendSummary
	let style: FriendStatusCardStyle
	@Default(.schoolCalendar) private var schoolCalendar

	private var displayName: String {
		friend.friend.displayName
	}

	init(friend: FriendSummary, style: FriendStatusCardStyle = .list) {
		self.friend = friend
		self.style = style
	}

	var body: some View {
		TimelineView(.periodic(from: .now, by: 30)) { context in
			let scheduleStatus = FriendScheduleStatus(
				subjects: friend.timetable?.subjects ?? [],
				at: TimetableClock.adjusted(context.date),
				schoolCalendar: schoolCalendar
			)
			let locationStatus = FriendLocationStatus(
				item: friend.locationStatus,
				at: TimetableClock.adjusted(context.date)
			)
			HStack(alignment: .center, spacing: 14) {
				if style == .list {
					FriendAvatar(profile: friend.friend)
				}

				VStack(alignment: .leading, spacing: style == .detail ? 7 : 5) {
					if style == .list {
						HStack(alignment: .top) {
							Text(displayName)
								.font(.title3.weight(.semibold))
							Spacer()
							locationBadge(locationStatus)
						}
						.padding([.top, .trailing], style == .list ? 7 : 0)
					}

					HStack(spacing: 6) {
						Image(systemName: scheduleStatus.symbol)
						Text(scheduleStatus.title)
						if style == .detail {
							Spacer()
							VStack(alignment: .trailing, spacing: 4) {
								locationBadge(locationStatus)
								if let statusTime = locationStatus.statusTime {
									Text(statusTime)
										.font(.caption2)
										.foregroundStyle(.secondary)
								}
							}
						}
					}
					.font(style == .detail ? .title3 : .body)
					.contentTransition(.numericText())

					Text(nextClassTitle(for: scheduleStatus))
						.font(style == .detail ? .body : .caption)
						.foregroundStyle(.secondary)
				}
			}
			.foregroundStyle(.white)
			.padding(style == .detail ? 14 : 10)
			.background {
				FriendGrayPaperBackground(cornerRadius: 28)
			}
			.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
			.contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
			.animation(.bouncy, value: scheduleStatus.title)
		}
	}

	private func locationBadge(_ locationStatus: FriendLocationStatus) -> some View {
		Text(locationStatus.title)
			.fontWeight(.medium)
			.font(.caption)
			.padding(5)
			.glassEffect(
				.regular.tint(locationStatus.tint ?? nil).interactive(),
				in: Capsule()
			)
			.foregroundStyle(.white)
	}

	private func nextClassTitle(for status: FriendScheduleStatus) -> String {
		if status.nextTitle == "Last Period" {
			status.nextTitle
		} else if status.nextTitle.hasPrefix("Next:") || status.nextTitle == "No upcoming classes" {
			status.nextTitle
		} else {
			"Next: \(status.nextTitle)"
		}
	}
}

private struct FriendLocationStatus {
	let title: String
	let tint: Color?
	let statusTime: String?

	init(item: LocationStatusItem?, at date: Date) {
		guard let item else {
			title = "Status unavailable"
			tint = nil
			statusTime = nil
			return
		}

		switch item.state {
			case .onCampus:
				title = "On Campus"
				tint = .green
				statusTime = "Arrived: \(item.updatedAt.formatted(date: .omitted, time: .shortened))"

			case .offCampus:
				title = "Off Campus"
				tint = Self.isDuringSchoolHours(at: date) ? .red : .blue
				statusTime = "Left: \(item.updatedAt.formatted(date: .omitted, time: .shortened))"
		}
	}

	private static func isDuringSchoolHours(at date: Date) -> Bool {
		let calendar = SchoolCalendarProjection.perthCalendar
		let components = calendar.dateComponents(
			[.weekday, .hour, .minute],
			from: date
		)

		guard
			let weekday = components.weekday,
			let hour = components.hour,
			let minute = components.minute
		else {
			return false
		}

		let minutes = hour * 60 + minute
		let schoolStart = 8 * 60 + 50

		let schoolEnd: Int

		switch weekday {
			case 2, 3, 5: // Monday, Tuesday, Thursday
				schoolEnd = 15 * 60 + 30

			case 4, 6: // Wednesday, Friday
				schoolEnd = 14 * 60 + 30

			default: // Saturday, Sunday
				return false
		}

		return minutes >= schoolStart && minutes < schoolEnd
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
