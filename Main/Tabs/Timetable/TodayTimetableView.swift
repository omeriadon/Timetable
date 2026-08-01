import Defaults
import SwiftUI

struct TodayTimetableView: View {
	let subjects: [Subject]
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.calendarEvents) private var calendarEvents
	@State private var expandedPeriodNumber: Int?

	var body: some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			let now = TimetableClock.adjusted(context.date)
			let schoolEvents = todayEvents(in: calendarEvents.globalEvents, at: now)
			let personalEvents = todayEvents(in: calendarEvents.privateEvents, at: now)
			let upcomingEvents = upcomingEvents(at: now)
			let noSchoolDay = schoolCalendar.skippedDates.first { $0.date == SchoolCalendarDate(now) }
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).hour(.defaultDigits(amPM: .wide)).minute(.defaultDigits).second(.defaultDigits)))
						.contentTransition(.numericText())
						.animation(.easeInOut, value: now)
						.frame(maxWidth: .infinity, alignment: .center)
						.multilineTextAlignment(.center)
						.lineLimit(1)
						.font(.system(size: 200))
						.minimumScaleFactor(0.01)
						.foregroundStyle(.white)

					if let noSchoolDay {
						TodayNoSchoolDayCard(noSchoolDay: noSchoolDay)
					}

					if !schoolEvents.isEmpty || !personalEvents.isEmpty || !upcomingEvents.isEmpty {
						VStack(alignment: .leading) {
							Text("Events Today")
								.font(.title)
								.bold()

							if !schoolEvents.isEmpty {
								eventSection("School Events", events: schoolEvents)
							}

							if !personalEvents.isEmpty {
								eventSection("Your Events", events: personalEvents)
							}

							if !upcomingEvents.isEmpty {
								eventSection("Upcoming Events", events: upcomingEvents, showsDate: true)
							}
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.vertical, 10)
						.padding(.bottom, 5)
						.padding(.horizontal, TodayCardLayout.contentInset)
						.background {
							GeometryReader { proxy in
								Image("paper")
									.resizable()
									.scaledToFill()
									.frame(width: proxy.size.width, height: proxy.size.height)
									.clipped()
							}
							.clipShape(RoundedRectangle(cornerRadius: TodayCardLayout.outerCornerRadius))
						}
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: TodayCardLayout.outerCornerRadius))
					}

					if let dayIndex = schoolCalendar.dayIndex(for: now), schoolCalendar.isSchoolDay(now), !subjects.isEmpty {
						TodaySchoolTimeline(
							subjects: subjects,
							dayIndex: dayIndex,
							now: now,
							expandedPeriodNumber: $expandedPeriodNumber
						)
					} else if schoolEvents.isEmpty, personalEvents.isEmpty, upcomingEvents.isEmpty, noSchoolDay == nil {
						TodayCountdown(subjects: subjects, schoolCalendar: schoolCalendar, now: now)
					}
				}
				.foregroundStyle(.black)
				.padding(.vertical)
				.padding(.horizontal, 10)
				.frame(maxWidth: .infinity, alignment: .center)
			}
		}
	}

	@ViewBuilder private func eventSection(_ title: String, events: [CalendarEvent], showsDate: Bool = false) -> some View {
		Text(title)
			.fontWeight(.semibold)
			.foregroundStyle(title == "Upcoming Events" ? .tertiary : .secondary)
			.padding(.top, 4)

		ForEach(events) { event in
			Label {
				VStack(alignment: .leading) {
					Text(event.title)
						.foregroundStyle(.secondary)

					if showsDate {
						Text(event.date.displayLabel)
							.font(.footnote)
							.foregroundStyle(.tertiary)
					}
				}
			} icon: {
				Image(systemName: event.symbol)
					.foregroundStyle(.secondary)
			}
			.padding(.vertical, 4)
			.font(.title3)
			.padding(5)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background {
				GeometryReader { proxy in
					Image("paperWhite")
						.resizable()
						.scaledToFill()
						.opacity(title == "Upcoming Events" ? 0.9 : 1)
						.frame(width: proxy.size.width, height: proxy.size.height)
						.clipped()
				}
				.clipShape(RoundedRectangle(cornerRadius: TodayCardLayout.innerCornerRadius))
			}
			.glassEffect(title == "Upcoming Events" ? .identity : .clear.interactive(), in: RoundedRectangle(cornerRadius: TodayCardLayout.innerCornerRadius))
		}
	}

	private func todayEvents(in events: [CalendarEvent], at date: Date) -> [CalendarEvent] {
		let today = SchoolCalendarDate(date)
		return events
			.filter { $0.date == today }
			.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
	}

	private func upcomingEvents(at date: Date) -> [CalendarEvent] {
		let calendar = SchoolCalendarProjection.perthCalendar
		let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
		let nextWeek = calendar.date(byAdding: .day, value: 7, to: date) ?? date
		let dateWindow = SchoolCalendarDate(tomorrow, calendar: calendar) ... SchoolCalendarDate(nextWeek, calendar: calendar)

		return (calendarEvents.globalEvents + calendarEvents.privateEvents)
			.filter { dateWindow.contains($0.date) }
			.sorted {
				if $0.date == $1.date {
					return $0.title.localizedStandardCompare($1.title) == .orderedAscending
				}

				return $0.date < $1.date
			}
	}
}

private enum TodayCardLayout {
	static let outerCornerRadius: CGFloat = 25
	static let innerCornerRadius: CGFloat = 13
	static let contentInset: CGFloat = 14
}

private struct TodayNoSchoolDayCard: View {
	let noSchoolDay: SchoolCalendarNamedDate

	var body: some View {
		VStack(alignment: .leading) {
			Text("No School Today")
				.bold()

			Label {
				VStack(alignment: .leading) {
					Text(noSchoolDay.label)
					Text(noSchoolDay.date.displayLabel)
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			} icon: {
				Image(systemName: "xmark.circle")
			}
			.padding(.vertical, 4)
			.font(.title3)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.vertical, 10)
		.padding(.horizontal, TodayCardLayout.contentInset)
		.background {
			GeometryReader { proxy in
				Image("paperWhite")
					.resizable()
					.scaledToFill()
					.frame(width: proxy.size.width, height: proxy.size.height)
					.clipped()
			}
			.clipShape(RoundedRectangle(cornerRadius: 20))
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 20))
	}
}

private struct TodayCountdown: View {
	let subjects: [Subject]
	let schoolCalendar: SchoolCalendarProjection
	let now: Date

	var body: some View {
		if let next = SchoolStateEngine.nextScheduledSubject(after: now, subjects: subjects, schoolCalendar: schoolCalendar) {
			VStack(spacing: 20) {
				Image(systemName: "face.dashed")
					.font(.largeTitle.scaled(by: 1.3))
					.foregroundStyle(.accent)
					.bold()

				Text("Nothing Scheduled Today")
					.foregroundStyle(.secondary)
					.font(.title2)
					.multilineTextAlignment(.center)

				Text("Next: \(next.subject.id)")
					.foregroundStyle(.tertiary)
			}
			.frame(maxWidth: .infinity, alignment: .center)
			.foregroundStyle(.white)
			.padding(.top, 40)

		} else {
			ContentUnavailableView("Nothing Scheduled", systemImage: "calendar")
				.foregroundStyle(.white)
				.padding(.top, 40)
		}
	}

	private func countdownText(until target: Date) -> String {
		let seconds = max(0, Int(target.timeIntervalSince(now)))
		return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
	}
}

private struct TodaySchoolTimeline: View {
	let subjects: [Subject]
	let dayIndex: Int
	let now: Date
	@Binding var expandedPeriodNumber: Int?
	private let minuteHeight: CGFloat = 1.35
	private let outerCornerRadius = TodayCardLayout.outerCornerRadius
	private let periodCornerRadius = TodayCardLayout.innerCornerRadius
	private let timelineHorizontalPadding: CGFloat = 3
	private let periodHorizontalInset = TodayCardLayout.contentInset

	/// Pulled these out of `body` into computed properties so both `body`
	/// and `periodsLayer` can reference them without re-deriving anything
	/// or capturing local `let`s across a view boundary.
	private var periods: [SchoolPeriod] {
		SchoolStateEngine.activePeriods(for: dayIndex)
	}

	private var dayEnd: TimeOfDay {
		SchoolStateEngine.schoolEnd(for: dayIndex)
	}

	private var totalMinutes: Int {
		dayEnd.minutesSinceMidnight - SchoolStateEngine.schoolStart.minutesSinceMidnight
	}

	private var height: CGFloat {
		CGFloat(totalMinutes) * minuteHeight
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Classes")
				.font(.title)
				.bold()
				.padding(.horizontal, periodHorizontalInset - timelineHorizontalPadding)

			// A bare GeometryReader always greedily expands to fill all
			// available space before any downstream .frame() applies —
			// that's what was making this section balloon. Fixing the
			// size first with Color.clear, then handing the
			// GeometryReader that resolved size via .overlay, keeps it
			// pinned to `height` instead of expanding.
			Color.clear
				.frame(height: height)
				.overlay(alignment: .topLeading) { periodsLayer }
		}
		.foregroundStyle(.black)
		.padding(.top, 10)
		.padding(.bottom, 8)
		.padding(.horizontal, timelineHorizontalPadding)
		.background {
			GeometryReader { proxy in
				Image("paper")
					.resizable()
					.scaledToFill()
					.frame(width: proxy.size.width, height: proxy.size.height)
					.clipped()
			}
			.clipShape(RoundedRectangle(cornerRadius: outerCornerRadius))
		}
		.glassEffect(.clear, in: RoundedRectangle(cornerRadius: outerCornerRadius))
	}

	private var periodsLayer: some View {
		GeometryReader { geometry in
			GlassEffectContainer(spacing: 10) {
				ZStack(alignment: .topLeading) {
					ForEach(periods, id: \.number) { period in
						periodRow(period)
							.frame(width: periodRowWidth(for: geometry.size.width))
							.offset(
								x: periodHorizontalInset - timelineHorizontalPadding,
								y: offset(for: period.start)
							)
					}
				}
				.frame(width: geometry.size.width, height: height, alignment: .topLeading)
			}
			.overlay(alignment: .topLeading) {
				if let firstPeriod = periods.first,
				   currentMinute >= markerDisplayStart,
				   currentMinute <= dayEnd.minutesSinceMidnight
				{
					currentTimeMarker
						.offset(y: markerOffset(for: firstPeriod))
				}
			}
			.frame(width: geometry.size.width, height: height, alignment: .topLeading)
		}
	}

	@ViewBuilder private func periodRow(_ period: SchoolPeriod) -> some View {
		let subject = subject(for: period)
		let duration = CGFloat(period.end.minutesSinceMidnight - period.start.minutesSinceMidnight) * minuteHeight
		let isExpanded = expandedPeriodNumber == period.number
		let baseCardHeight = max(44, duration - 8)
		let cardHeight = baseCardHeight + (isExpanded ? 48 : 0)

		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .top) {
				HStack(alignment: .top, spacing: 10) {
					Text("\(period.number)")
						.font(.caption.monospacedDigit())
						.frame(width: 15)

					VStack(alignment: .leading, spacing: 4) {
						Text(subject?.id ?? "Free Period")
							.lineLimit(2)
							.font(.title2)

						if isExpanded, let subject {
							Label(subject.teacher.displayName, systemImage: "person.fill")
								.font(.subheadline)
								.foregroundStyle(.secondary)

							Label(subject.classroom.displayName, systemImage: "door.left.hand.open")
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}
					}
				}
				.frame(maxHeight: .infinity, alignment: .topLeading)

				Spacer()

				if let subject {
					Image(systemName: subject.symbol)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: max(18, baseCardHeight - 40), height: max(18, baseCardHeight - 40))
						.padding(.trailing, 10)
						.foregroundStyle(subject.colour.swiftUIColor)
				}
			}
		}
		.padding(10)
		.frame(height: cardHeight, alignment: .top)
		.onTapGesture {
			withAnimation(.snappy(duration: 0.28)) {
				expandedPeriodNumber = isExpanded ? nil : period.number
			}
		}

		.accessibilityLabel(subject?.id ?? "Free Period")
		.accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
		.background {
			GeometryReader { proxy in
				Image("paperWhite")
					.resizable()
					.scaledToFill()
					.frame(width: proxy.size.width, height: proxy.size.height)
					.clipped()
			}
			.clipShape(RoundedRectangle(cornerRadius: periodCornerRadius, style: .continuous))
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: periodCornerRadius, style: .continuous))
	}

	private var currentTimeMarker: some View {
		Color.clear
			.frame(maxWidth: .infinity, alignment: .leading)
			.frame(height: 15)
			.glassEffect(.regular.tint(.red), in: CurrentTimeMarkerShape())
			.padding(.horizontal, -1)
			.accessibilityLabel("Current time")
	}

	private func periodRowWidth(for availableWidth: CGFloat) -> CGFloat {
		availableWidth - 2 * (periodHorizontalInset - timelineHorizontalPadding)
	}

	private var currentMinute: Int {
		let calendar = SchoolCalendarProjection.perthCalendar
		return calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
	}

	private var markerDisplayStart: Int {
		TimeOfDay(8, 0).minutesSinceMidnight
	}

	private func markerOffset(for firstPeriod: SchoolPeriod) -> CGFloat {
		guard currentMinute < firstPeriod.start.minutesSinceMidnight else {
			return CGFloat(currentMinute - SchoolStateEngine.schoolStart.minutesSinceMidnight) * minuteHeight - 4
		}

		return -15
	}

	private func offset(for time: TimeOfDay) -> CGFloat {
		CGFloat(time.minutesSinceMidnight - SchoolStateEngine.schoolStart.minutesSinceMidnight) * minuteHeight
	}

	private func subject(for period: SchoolPeriod) -> Subject? {
		guard let session = TimetableLayout.session(forPeriod: period.number) else { return nil }
		return TimetableLayout.subjectLookup(for: subjects)[Slot(dayIndex, session)]
	}

	private func timeLabel(_ time: TimeOfDay) -> String {
		String(format: "%d:%02d", time.hour, time.minute)
	}
}

private struct CurrentTimeMarkerShape: Shape {
	func path(in rect: CGRect) -> Path {
		let circleDiameter = min(15, rect.height)
		let circleY = rect.midY - circleDiameter / 2
		let lineHeight: CGFloat = 5
		let lineStart = circleDiameter / 2
		let lineRect = CGRect(
			x: lineStart,
			y: rect.midY - lineHeight / 2,
			width: max(0, rect.width - lineStart),
			height: lineHeight
		)

		var path = Path()
		path.addEllipse(in: CGRect(x: 0, y: circleY, width: circleDiameter, height: circleDiameter))
		path.addRoundedRect(in: lineRect, cornerSize: CGSize(width: lineHeight / 2, height: lineHeight / 2))
		return path
	}
}
