import Defaults
import SwiftUI

struct TodayTimetableView: View {
	let subjects: [Subject]
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.calendarEvents) private var calendarEvents
	@Default(.gradeTracker) private var gradeTracker
	@Default(.schoolWeather) private var schoolWeather
	@State private var expandedPeriodNumber: Int?
	@State private var eventSnapshot = TodayEventSnapshot.empty
	@State private var weatherService = SchoolWeatherService.shared

	var body: some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			TodayTimetableContent(
				subjects: subjects,
				schoolCalendar: schoolCalendar,
				calendarEvents: calendarEvents,
				gradeTracker: gradeTracker,
				schoolWeather: schoolWeather,
				now: TimetableClock.adjusted(context.date),
				expandedPeriodNumber: $expandedPeriodNumber,
				eventSnapshot: $eventSnapshot
			)
		}
		.task {
			try? await weatherService.refresh()
		}
	}
}

private struct TodayTimetableContent: View {
	let subjects: [Subject]
	let schoolCalendar: SchoolCalendarProjection
	let calendarEvents: CalendarEventsProjection
	let gradeTracker: GradeTrackerDocument
	let schoolWeather: SchoolWeather?
	let now: Date
	@Binding var expandedPeriodNumber: Int?
	@Binding var eventSnapshot: TodayEventSnapshot

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				TodayHeader(weather: schoolWeather, now: now, termWeekLabel: termWeekLabel)

				if let noSchoolDay = eventSnapshot.noSchoolDay {
					TodayNoSchoolDayCard(noSchoolDay: noSchoolDay)
				}

				if !eventSnapshot.todayEntries.isEmpty || !eventSnapshot.upcomingEntries.isEmpty {
					TodayEventsCard(
						todayEntries: eventSnapshot.todayEntries,
						upcomingEntries: eventSnapshot.upcomingEntries
					)
				}

				if let dayIndex = schoolCalendar.dayIndex(for: now), schoolCalendar.isSchoolDay(now), !subjects.isEmpty {
					TodaySchoolTimeline(
						subjects: subjects,
						dayIndex: dayIndex,
						now: now,
						expandedPeriodNumber: $expandedPeriodNumber
					)
				} else if eventSnapshot.isEmpty {
					TodayCountdown(subjects: subjects, schoolCalendar: schoolCalendar, now: now)
				}
			}
			.padding(.vertical)
			.padding(.horizontal, 10)
			.frame(maxWidth: .infinity, alignment: .center)
		}
		.task(id: snapshotInput) {
			eventSnapshot = TodayEventSnapshot(
				calendarEvents: calendarEvents,
				gradeTracker: gradeTracker,
				subjects: subjects,
				schoolCalendar: schoolCalendar,
				day: SchoolCalendarDate(now)
			)
		}
	}

	private var snapshotInput: TodayEventSnapshotInput {
		TodayEventSnapshotInput(
			calendarEvents: calendarEvents,
			gradeTracker: gradeTracker,
			subjects: subjects,
			schoolCalendar: schoolCalendar,
			day: SchoolCalendarDate(now)
		)
	}

	private var termWeekLabel: String? {
		let schoolDate = SchoolCalendarDate(now)
		guard let term = schoolCalendar.termRanges.first(where: { range in
			range.start <= schoolDate && schoolDate <= range.end
		}) else {
			return nil
		}

		let termNumber = term.label
			.split(whereSeparator: { !$0.isNumber })
			.first
			.map(String.init) ?? "?"
		let start = monday(of: term.start.startOfDay() ?? now)
		let current = monday(of: schoolDate.startOfDay() ?? now)
		let elapsedDays = SchoolCalendarProjection.perthCalendar
			.dateComponents([.day], from: start, to: current)
			.day ?? 0

		return "Term \(termNumber), Week \(elapsedDays / 7 + 1)"
	}

	private func monday(of date: Date) -> Date {
		let calendar = SchoolCalendarProjection.perthCalendar
		let weekday = calendar.component(.weekday, from: date)
		let daysFromMonday = (weekday + 6) % 7
		return calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
	}
}

private struct TodayHeader: View {
	let weather: SchoolWeather?
	let now: Date
	let termWeekLabel: String?

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			if let weather {
				SchoolWeatherSummary(
					weather: weather,
					font: .caption,
					foregroundStyle: .black
				)
			}

			Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).hour(.defaultDigits(amPM: .wide)).minute(.defaultDigits).second(.defaultDigits)))
				.contentTransition(.numericText())
				.animation(.easeInOut, value: now)
				.frame(maxWidth: .infinity, alignment: .leading)
				.lineLimit(1)
				.font(.system(size: 200))
				.minimumScaleFactor(0.01)
				.foregroundStyle(.primary)

			if let termWeekLabel {
				Text(termWeekLabel)
					.font(.title3)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		.foregroundStyle(.primary)
		.padding(.leading, 6)
	}
}

private struct TodayEventsCard: View {
	let todayEntries: [TodayEventEntry]
	let upcomingEntries: [TodayEventEntry]

	var body: some View {
		VStack(alignment: .leading) {
			Text("Events")
				.font(.title)
				.bold()

			if !todayEntries.isEmpty {
				TodayEventSection(title: "Today", entries: todayEntries)
			}

			if !upcomingEntries.isEmpty {
				TodayEventSection(title: "Upcoming", entries: upcomingEntries, showsDate: true)
			}
		}
		.foregroundStyle(.black)
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
					.accessibilityHidden(true)
			}
			.clipShape(RoundedRectangle(cornerRadius: TodayCardLayout.outerCornerRadius))
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: TodayCardLayout.outerCornerRadius))
	}
}

private struct TodayEventSection: View {
	let title: String
	let entries: [TodayEventEntry]
	let showsDate: Bool

	init(title: String, entries: [TodayEventEntry], showsDate: Bool = false) {
		self.title = title
		self.entries = entries
		self.showsDate = showsDate
	}

	var body: some View {
		Text(title)
			.fontWeight(.semibold)
			.foregroundStyle(.black)
			.padding(.top, 4)

		ForEach(entries) { entry in
			TodayEventRow(entry: entry, showsDate: showsDate)
		}
	}
}

private struct TodayEventRow: View {
	let entry: TodayEventEntry
	let showsDate: Bool

	var body: some View {
		HStack {
			Image(systemName: entry.symbol)

			VStack(alignment: .leading) {
				Text(entry.title)

				if let weather = entry.weather {
					SchoolWeatherSummary(
						weather: weather,
						font: .caption,
						foregroundStyle: .black
					)
				}

				if showsDate {
					Text(entry.date.displayLabel)
						.font(.footnote)
						.foregroundStyle(.black)
				}
			}
		}
		.padding(.vertical, 4)
		.font(.title3)
		.padding(5)
		.frame(maxWidth: .infinity, alignment: .leading)
		.foregroundStyle(.black)
		.background {
			GeometryReader { proxy in
				Image(entry.backgroundImageName)
					.resizable()
					.scaledToFill()
					.frame(width: proxy.size.width, height: proxy.size.height)
					.clipped()
					.accessibilityHidden(true)
			}
			.clipShape(RoundedRectangle(cornerRadius: TodayCardLayout.innerCornerRadius))
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: TodayCardLayout.innerCornerRadius))
	}
}

private struct TodayEventSnapshotInput: Hashable {
	let calendarEvents: CalendarEventsProjection
	let gradeTracker: GradeTrackerDocument
	let subjects: [Subject]
	let schoolCalendar: SchoolCalendarProjection
	let day: SchoolCalendarDate
}

private struct TodayEventSnapshot: Equatable {
	let todayEntries: [TodayEventEntry]
	let upcomingEntries: [TodayEventEntry]
	let noSchoolDay: SchoolCalendarNamedDate?

	var isEmpty: Bool {
		todayEntries.isEmpty && upcomingEntries.isEmpty && noSchoolDay == nil
	}

	private init(
		todayEntries: [TodayEventEntry] = [],
		upcomingEntries: [TodayEventEntry] = [],
		noSchoolDay: SchoolCalendarNamedDate? = nil
	) {
		self.todayEntries = todayEntries
		self.upcomingEntries = upcomingEntries
		self.noSchoolDay = noSchoolDay
	}

	static let empty = TodayEventSnapshot()

	init(
		calendarEvents: CalendarEventsProjection,
		gradeTracker: GradeTrackerDocument,
		subjects: [Subject],
		schoolCalendar: SchoolCalendarProjection,
		day: SchoolCalendarDate
	) {
		let entries = Self.entries(
			calendarEvents: calendarEvents,
			assessments: gradeTracker.assessments,
			subjects: subjects
		)
		self.init(
			todayEntries: entries.filter { $0.date == day },
			upcomingEntries: Self.upcomingEntries(after: day, entries: entries),
			noSchoolDay: schoolCalendar.skippedDates.first { $0.date == day }
		)
	}

	private static func entries(
		calendarEvents: CalendarEventsProjection,
		assessments: [GradeAssessment],
		subjects: [Subject]
	) -> [TodayEventEntry] {
		let events = (calendarEvents.globalEvents + calendarEvents.privateEvents).map(TodayEventEntry.init(event:))
		let assessmentEntries = assessments.map { assessment in
			TodayEventEntry(
				assessment: assessment,
				subject: subjects.first { $0.id == assessment.subjectID }
			)
		}
		return (events + assessmentEntries).sorted(by: TodayEventEntry.areInDisplayOrder)
	}

	private static func upcomingEntries(
		after day: SchoolCalendarDate,
		entries: [TodayEventEntry]
	) -> [TodayEventEntry] {
		let calendar = SchoolCalendarProjection.perthCalendar
		let referenceDate = day.startOfDay(calendar: calendar) ?? .now
		let start = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
		let end = calendar.date(byAdding: .month, value: 2, to: referenceDate) ?? referenceDate
		let dateWindow = SchoolCalendarDate(start, calendar: calendar) ... SchoolCalendarDate(end, calendar: calendar)

		return entries
			.filter { dateWindow.contains($0.date) }
			.sorted(by: TodayEventEntry.areInDisplayOrder)
	}
}

private struct TodayEventEntry: Equatable, Identifiable {
	let id: String
	let title: String
	let date: SchoolCalendarDate
	let symbol: String
	let usesForegroundPaper: Bool
	let weather: SchoolWeather?

	var backgroundImageName: String {
		usesForegroundPaper ? "foregroundPaper" : "paper"
	}

	var foregroundColor: Color {
		usesForegroundPaper ? Color(.inversePrimary) : .primary
	}

	nonisolated init(event: CalendarEvent) {
		id = "event-\(event.id.uuidString)"
		title = event.title
		date = event.date
		symbol = event.symbol
		usesForegroundPaper = !event.isGlobal
		weather = event.weather
	}

	nonisolated init(assessment: GradeAssessment, subject: Subject?) {
		id = "assessment-\(assessment.id.uuidString)"
		title = assessment.name
		date = assessment.date
		symbol = subject?.symbol ?? "doc.text"
		usesForegroundPaper = true
		weather = nil
	}

	nonisolated static func areInDisplayOrder(_ lhs: Self, _ rhs: Self) -> Bool {
		if lhs.date == rhs.date {
			return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
		}

		return lhs.date < rhs.date
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
				Image("foregroundPaper")
					.resizable()
					.scaledToFill()
					.accessibilityHidden(true)
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
			.foregroundStyle(.primary)
			.padding(.top, 40)

		} else {
			ContentUnavailableView("Nothing Scheduled", systemImage: "calendar")
				.foregroundStyle(.primary)
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
	private let expandedContentHeight: CGFloat = 48

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
			+ (expandedPeriodNumber == nil ? 0 : expandedContentHeight)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Classes")
				.font(.title)
				.bold()
				.padding(.horizontal, periodHorizontalInset - timelineHorizontalPadding)

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
					.accessibilityHidden(true)
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
								y: offset(for: period)
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
		let cardHeight = baseCardHeight + (isExpanded ? expandedContentHeight : 0)

		TodaySchoolPeriodRow(
			periodNumber: period.number,
			subject: subject,
			isExpanded: isExpanded,
			baseCardHeight: baseCardHeight,
			cardHeight: cardHeight,
			cornerRadius: periodCornerRadius,
			toggleExpansion: {
				withAnimation(.snappy(duration: 0.28)) {
					expandedPeriodNumber = isExpanded ? nil : period.number
				}
			}
		)
	}

	private var currentTimeMarker: some View {
		GeometryReader { geo in
			Color.clear
				.frame(width: geo.size.width - 6, alignment: .center)
				.frame(height: 15)
				.glassEffect(.regular.tint(.red), in: CurrentTimeMarkerShape())
				.accessibilityLabel("Current time")
		}
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
			return CGFloat(currentMinute - SchoolStateEngine.schoolStart.minutesSinceMidnight) * minuteHeight
				+ expandedMarkerOffset(at: currentMinute)
				- 4
		}

		return -15
	}

	private func offset(for period: SchoolPeriod) -> CGFloat {
		CGFloat(period.start.minutesSinceMidnight - SchoolStateEngine.schoolStart.minutesSinceMidnight) * minuteHeight
			+ expandedContentOffset(before: period.start.minutesSinceMidnight)
	}

	private func expandedContentOffset(before minute: Int) -> CGFloat {
		guard let expandedPeriodNumber,
		      let expandedPeriod = periods.first(where: { $0.number == expandedPeriodNumber }),
		      expandedPeriod.end.minutesSinceMidnight <= minute
		else {
			return 0
		}

		return expandedContentHeight
	}

	private func expandedMarkerOffset(at minute: Int) -> CGFloat {
		guard let expandedPeriodNumber,
		      let expandedPeriod = periods.first(where: { $0.number == expandedPeriodNumber })
		else {
			return 0
		}

		let start = expandedPeriod.start.minutesSinceMidnight
		let end = expandedPeriod.end.minutesSinceMidnight
		if minute >= end {
			return expandedContentHeight
		}
		guard minute > start, end > start else {
			return 0
		}

		let progress = CGFloat(minute - start) / CGFloat(end - start)
		return expandedContentHeight * progress
	}

	private func subject(for period: SchoolPeriod) -> Subject? {
		guard let session = TimetableLayout.session(forPeriod: period.number) else { return nil }
		return TimetableLayout.subjectLookup(for: subjects)[Slot(dayIndex, session)]
	}

	private func timeLabel(_ time: TimeOfDay) -> String {
		String(format: "%d:%02d", time.hour, time.minute)
	}
}

private struct TodaySchoolPeriodRow: View {
	let periodNumber: Int
	let subject: Subject?
	let isExpanded: Bool
	let baseCardHeight: CGFloat
	let cardHeight: CGFloat
	let cornerRadius: CGFloat
	let toggleExpansion: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .center) {
				HStack(alignment: .center, spacing: 10) {
					Text(periodNumber.formatted())
						.font(.caption.monospacedDigit())
						.frame(width: 15)

					VStack(alignment: .leading, spacing: 4) {
						Text(subject?.id ?? "Free Period")
							.lineLimit(2)
							.font(.title2)

						if isExpanded, let subject {
							Label(subject.teacher.displayName, systemImage: "person.fill")
								.font(.headline)
								.foregroundStyle(.secondary)

							Label(subject.classroom.displayName, systemImage: "door.left.hand.open")
								.font(.headline)
								.foregroundStyle(.secondary)
						}
					}
				}
				.frame(maxHeight: .infinity, alignment: .leading)

				Spacer()

				if let subject {
					Image(systemName: subject.symbol)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(
							width: max(18, baseCardHeight - 40),
							height: max(18, baseCardHeight - 40)
						)
						.padding(.trailing, 10)
						.foregroundStyle(subject.colour.swiftUIColor)
				}
			}
		}
		.padding(10)
		.frame(height: cardHeight, alignment: .top)
		.foregroundStyle(.black)
		.accessibilityLabel(subject?.id ?? "Free Period")
		.accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
		.background {
			GeometryReader { proxy in
				Image("paperWhite")
					.resizable()
					.scaledToFill()
					.frame(width: proxy.size.width, height: proxy.size.height)
					.clipped()
					.accessibilityHidden(true)
			}
			.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		.contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		.onTapGesture(perform: toggleExpansion)
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
