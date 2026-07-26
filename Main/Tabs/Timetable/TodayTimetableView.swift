import Defaults
import SwiftUI

struct TodayTimetableView: View {
	let subjects: [Subject]
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.calendarEvents) private var calendarEvents

	var body: some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			let now = TimetableClock.adjusted(context.date)
			let schoolEvents = todayEvents(in: calendarEvents.globalEvents, at: now)
			let personalEvents = todayEvents(in: calendarEvents.privateEvents, at: now)
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide).hour(.defaultDigits(amPM: .wide)).minute(.defaultDigits).second(.defaultDigits)))
						.contentTransition(.numericText())
						.animation(.easeInOut, value: now)
						.font(.title2.bold())

					if !schoolEvents.isEmpty || !personalEvents.isEmpty {
						VStack(alignment: .leading) {
							Text("Events Today")
								.bold()

							if !schoolEvents.isEmpty {
								eventSection("School Events", events: schoolEvents)
							}

							if !personalEvents.isEmpty {
								eventSection("Your Events", events: personalEvents)
							}
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(10)
						.background {
							GeometryReader { proxy in
								Image("paper")
									.resizable()
									.scaledToFill()
									.frame(width: proxy.size.width, height: proxy.size.height)
									.clipped()
							}
							.clipShape(RoundedRectangle(cornerRadius: 20))
						}
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 20))
					}

					if let dayIndex = schoolCalendar.dayIndex(for: now), schoolCalendar.isSchoolDay(now), !subjects.isEmpty {
						TodaySchoolTimeline(subjects: subjects, dayIndex: dayIndex, now: now)
					} else if schoolEvents.isEmpty && personalEvents.isEmpty {
						TodayCountdown(subjects: subjects, schoolCalendar: schoolCalendar, now: now)
					}
				}
				.padding(.vertical)
				.padding(.horizontal, 5)
				.frame(maxWidth: .infinity, alignment: .center)
			}
		}
	}

	@ViewBuilder private func eventSection(_ title: String, events: [CalendarEvent]) -> some View {
		Text(title)
			.font(.footnote.weight(.semibold))
			.foregroundStyle(.secondary)
			.padding(.top, 4)

		ForEach(events) { event in
			Label {
				VStack(alignment: .leading) {
					Text(event.title)
					if let notes = event.notes, !notes.isEmpty {
						Text(notes).font(.footnote).foregroundStyle(.secondary)
					}
				}
			} icon: {
				Image(systemName: event.symbol)
			}
			.padding(.vertical, 4)
			.font(.title3)
		}
	}

	private func todayEvents(in events: [CalendarEvent], at date: Date) -> [CalendarEvent] {
		let today = SchoolCalendarDate(date)
		return events
			.filter { $0.date == today }
			.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
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
					.font(.title2)
					.multilineTextAlignment(.center)
					.bold()

				Text("Next class: \(next.subject.id)")

				Text(countdownText(until: next.interval.start))
					.font(.title3)
					.contentTransition(.numericText())
					.animation(.linear(duration: 0.2), value: countdownText(until: next.interval.start))
			}

			.padding(.top, 40)

		} else {
			ContentUnavailableView("Nothing Scheduled", systemImage: "calendar")
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
	private let minuteHeight: CGFloat = 1.35
	private let outerCornerRadius: CGFloat = 20
	private let periodCornerRadius: CGFloat = 13
	private let timelineHorizontalPadding: CGFloat = 3
	private var periodHorizontalInset: CGFloat { outerCornerRadius - periodCornerRadius }

	var body: some View {
		let periods = SchoolStateEngine.activePeriods(for: dayIndex)
		let dayEnd = SchoolStateEngine.schoolEnd(for: dayIndex)
		let totalMinutes = dayEnd.minutesSinceMidnight - SchoolStateEngine.schoolStart.minutesSinceMidnight
		let height = CGFloat(totalMinutes) * minuteHeight
		VStack(alignment: .leading, spacing: 8) {
			Text("Classes")
				.font(.headline)
				.padding(.horizontal, periodHorizontalInset - timelineHorizontalPadding)
			GeometryReader { geometry in
				GlassEffectContainer(spacing: 10) {
					ZStack(alignment: .topLeading) {
						ForEach(periods, id: \.number) { period in
							periodRow(period)
								.offset(y: offset(for: period.start))
						}
						.padding(.horizontal, periodHorizontalInset - timelineHorizontalPadding)
					}
					.frame(width: geometry.size.width, height: height, alignment: .topLeading)
				}
				.overlay(alignment: .topLeading) {
					if currentMinute >= SchoolStateEngine.schoolStart.minutesSinceMidnight, currentMinute <= dayEnd.minutesSinceMidnight {
						currentTimeMarker
							.offset(y: CGFloat(currentMinute - SchoolStateEngine.schoolStart.minutesSinceMidnight) * minuteHeight - 4)
					}
				}
				.frame(width: geometry.size.width, height: height, alignment: .topLeading)
			}
			.frame(height: height)
		}
		.padding(.vertical, 10)
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
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: outerCornerRadius))
	}

	@ViewBuilder private func periodRow(_ period: SchoolPeriod) -> some View {
		let subject = subject(for: period)
		let duration = CGFloat(period.end.minutesSinceMidnight - period.start.minutesSinceMidnight) * minuteHeight
		let cardHeight = max(44, duration - 8)
		HStack(alignment: .top, spacing: 10) {
			Text("\(period.number)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 22)

			Text(subject?.id ?? "Free Period").font(.headline)

			Spacer()

			if let subject {
				Image(systemName: subject.symbol)
					.foregroundStyle(subject.colour.swiftUIColor)
					.font(.title)
			}
		}
		.padding(10)
		.frame(height: cardHeight, alignment: .top)
		.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: periodCornerRadius, style: .continuous))
	}

	private var currentTimeMarker: some View {
		HStack(spacing: -7) {
			Color.clear
				.frame(width: 15, height: 15)
				.glassEffect(.regular.tint(.red), in: Circle())
			Color.clear
				.frame(maxWidth: .infinity)
				.frame(height: 5)
				.glassEffect(.regular.tint(.red), in: Capsule())
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, -3)
		.accessibilityLabel("Current time")
	}

	private var currentMinute: Int {
		let calendar = SchoolCalendarProjection.perthCalendar
		return calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
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
