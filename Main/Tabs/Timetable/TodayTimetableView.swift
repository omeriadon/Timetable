import SwiftUI

struct TodayTimetableView: View {
	let subjects: [Subject]
	let schoolCalendar: SchoolCalendarProjection
	let events: [CalendarEvent]

	var body: some View {
		TimelineView(.periodic(from: .now, by: 30)) { context in
			let now = TimetableClock.adjusted(context.date)
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
						.font(.title2.bold())
					if !todayEvents(at: now).isEmpty {
						Section("Events") {
							ForEach(todayEvents(at: now)) { event in
								Label {
									VStack(alignment: .leading) {
										Text(event.title)
										if let notes = event.notes, !notes.isEmpty {
											Text(notes).font(.footnote).foregroundStyle(.secondary)
										}
									}
								} icon: { Image(systemName: event.symbol) }
									.padding(.vertical, 4)
							}
						}
					}
					if let dayIndex = schoolCalendar.dayIndex(for: now), schoolCalendar.isSchoolDay(now), !subjects.isEmpty {
						TodaySchoolTimeline(subjects: subjects, dayIndex: dayIndex, now: now)
					} else if todayEvents(at: now).isEmpty {
						TodayCountdown(subjects: subjects, schoolCalendar: schoolCalendar, now: now)
					}
				}
				.padding()
			}
		}
	}

	private func todayEvents(at date: Date) -> [CalendarEvent] {
		let today = SchoolCalendarDate(date)
		return events.filter { $0.date == today }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
	}
}

private struct TodayCountdown: View {
	let subjects: [Subject]
	let schoolCalendar: SchoolCalendarProjection
	let now: Date

	var body: some View {
		if let next = SchoolStateEngine.nextScheduledSubject(after: now, subjects: subjects, schoolCalendar: schoolCalendar) {
			ContentUnavailableView {
				Label("Nothing Scheduled Today", systemImage: "calendar")
			} description: {
				VStack(spacing: 8) {
					Text("Next class: \(next.subject.id)")
					Text(timerInterval: now ... next.interval.start, countsDown: true, showsHours: true)
						.font(.title3.monospacedDigit())
				}
			}
		} else {
			ContentUnavailableView("Nothing Scheduled", systemImage: "calendar")
		}
	}
}

private struct TodaySchoolTimeline: View {
	let subjects: [Subject]
	let dayIndex: Int
	let now: Date
	private let minuteHeight: CGFloat = 1.35

	var body: some View {
		let periods = SchoolStateEngine.activePeriods(for: dayIndex)
		let dayEnd = SchoolStateEngine.schoolEnd(for: dayIndex)
		let totalMinutes = dayEnd.minutesSinceMidnight - SchoolStateEngine.schoolStart.minutesSinceMidnight
		let height = CGFloat(totalMinutes) * minuteHeight
		VStack(alignment: .leading, spacing: 8) {
			Text("Classes").font(.headline)
			GeometryReader { geometry in
				ZStack(alignment: .topLeading) {
					ForEach(periods, id: \.number) { period in periodRow(period).offset(y: offset(for: period.start)) }
					if currentMinute >= SchoolStateEngine.schoolStart.minutesSinceMidnight, currentMinute <= dayEnd.minutesSinceMidnight {
						HStack(spacing: 0) {
							Circle().fill(.red).frame(width: 8, height: 8)
							Rectangle().fill(.red).frame(height: 2)
						}
						.offset(y: CGFloat(currentMinute - SchoolStateEngine.schoolStart.minutesSinceMidnight) * minuteHeight - 4)
						.accessibilityLabel("Current time")
					}
				}
				.frame(width: geometry.size.width, height: height, alignment: .topLeading)
			}
			.frame(height: height)
		}
	}

	@ViewBuilder private func periodRow(_ period: SchoolPeriod) -> some View {
		let subject = subject(for: period)
		let duration = CGFloat(period.end.minutesSinceMidnight - period.start.minutesSinceMidnight) * minuteHeight
		HStack(alignment: .top, spacing: 10) {
			Text("\(period.number)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 22)
			VStack(alignment: .leading, spacing: 4) {
				Text(subject?.id ?? "Free Period").font(.headline)
				Text("\(timeLabel(period.start)) – \(timeLabel(period.end))").font(.caption).foregroundStyle(.secondary)
			}
			Spacer()
			if let subject {
				Image(systemName: subject.symbol).foregroundStyle(subject.colour.swiftUIColor)
			}
		}
		.padding(10)
		.frame(height: duration, alignment: .top)
		.background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
