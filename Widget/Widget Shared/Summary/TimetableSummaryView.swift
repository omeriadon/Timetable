//
//  TimetableSummaryView.swift
//  Timetable
//
//  Created by Adon Omeri on 31/7/2026.
//

import SwiftUI
import WidgetKit

struct TimetableSummaryView: View {
	let entry: TimetableEntry

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			header

			Spacer(minLength: 1)

			Divider()

			friendSection

			Spacer(minLength: 1)

			if !entry.upcomingEvents.isEmpty {
				Divider()
				eventSection
			}
		}
		.foregroundStyle(.white)
		.dynamicTypeSize(.medium)
		.monospaced()
	}

	private var header: some View {
		HStack(alignment: .center, spacing: 10) {
			if let countdown = countdownTarget {
				Text(timerInterval: TimetableClock.adjusted(entry.date) ... countdown, countsDown: true, showsHours: true)
					.font(.headline.monospacedDigit())
					.lineLimit(1)
			}

			Spacer()

			WidgetProfilePicture(
				profile: entry.ownerSchedule?.profile,
				fallbackSymbol: ownerSymbol,
				size: 34
			)

			Text(ownerTitle)
				.font(.headline)
				.lineLimit(1)
		}
	}

	private var friendSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Label("Friends", systemImage: "person.2.fill")
				.font(.caption)
				.foregroundStyle(.tertiary)

			ForEach(entry.friendSchedules.prefix(3)) { schedule in
				HStack(spacing: 8) {
					WidgetProfilePicture(
						profile: schedule.profile,
						fallbackSymbol: symbol(for: schedule.currentState),
						size: 28
					)
					Text(schedule.name)
						.font(.subheadline.monospaced())
						.foregroundStyle(.secondary)
						.lineLimit(1)
					Spacer()
					Text(title(for: schedule.currentState))
						.font(.caption)
						.lineLimit(1)
				}
			}
		}
	}

	private var eventSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Label("Upcoming Events", systemImage: "calendar")
				.font(.caption)
				.foregroundStyle(.tertiary)

			ForEach(entry.upcomingEvents.prefix(3)) { event in
				HStack(spacing: 8) {
					Image(systemName: event.symbol)
						.frame(width: 18)
					Text(event.title)
						.font(.subheadline)
						.lineLimit(1)
					Spacer()

					if let date = event.date.date {
						Text(date, format: .dateTime.day().month(.abbreviated))
							.font(.caption)
							.foregroundStyle(.secondary)
							.lineLimit(1)
					}
				}
			}
		}
	}

	private var ownerTitle: String {
		guard let schedule = entry.ownerSchedule else {
			return "No Timetable"
		}
		return title(for: schedule.currentState)
	}

	private var ownerSymbol: String {
		guard let schedule = entry.ownerSchedule else {
			return "calendar.badge.exclamationmark"
		}
		return symbol(for: schedule.currentState)
	}

	private var countdownTarget: Date? {
		guard let schedule = entry.ownerSchedule else {
			return nil
		}

		switch schedule.currentState {
			case let .beforeSchool(next):
				return next.interval.start
			case let .lesson(lesson):
				return lesson.interval.end
			case let .freePeriod(period):
				return period.interval.end
			case let .recess(state), let .lunch(state):
				return state.interval.end
			case .afterSchool, .weekend:
				return schedule.nextScheduledSubject?.interval.start
			case .noTimetable:
				return nil
		}
	}

	private func title(for state: SchoolState) -> String {
		switch state {
			case let .beforeSchool(next):
				next.subject.id
			case let .lesson(lesson):
				lesson.subject.id
			case .freePeriod:
				"Free Period"
			case .recess:
				BreakType.recess.description
			case .lunch:
				BreakType.lunch.description
			case .afterSchool, .weekend:
				"School's Out"
			case .noTimetable:
				"No Timetable"
		}
	}

	private func symbol(for state: SchoolState) -> String {
		switch state {
			case let .beforeSchool(next):
				next.subject.symbol
			case let .lesson(lesson):
				lesson.subject.symbol
			case .freePeriod:
				"studentdesk"
			case .recess:
				BreakType.recess.symbol
			case .lunch:
				BreakType.lunch.symbol
			case .afterSchool, .weekend:
				"house.fill"
			case .noTimetable:
				"calendar.badge.exclamationmark"
		}
	}
}

private struct WidgetProfilePicture: View {
	let profile: ScheduleProfile?
	let fallbackSymbol: String
	let size: CGFloat

	var body: some View {
		ZStack {
			if let profile {
				LinearGradient(
					colors: profile.appearance.colours.map(\.swiftUIColor),
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)

				profileContent(profile)
			} else {
				Color.secondary.opacity(0.2)

				Image(systemName: fallbackSymbol)
					.font(.system(size: size * 0.42, weight: .semibold))
			}
		}
		.frame(width: size, height: size)
		.clipShape(Circle())
		.overlay(alignment: .bottomTrailing) {
			if let badge = profile?.badges
				.sorted(by: { $0.priority > $1.priority })
				.first
			{
				Image(systemName: badge.symbol)
					.font(.system(size: size * 0.16, weight: .bold))
					.foregroundStyle(badge.symbolColor?.swiftUIColor ?? .white)
					.frame(width: size * 0.28, height: size * 0.28)
					.background(
						badge.backgroundColor?.swiftUIColor ?? .black,
						in: Circle()
					)
			}
		}
	}

	@ViewBuilder
	private func profileContent(_ profile: ScheduleProfile) -> some View {
		switch profile.appearance.contentKind {
			case .photo:
				if let photo = profile.photo,
				   let image = WidgetProfilePhotoCache.image(for: photo)
				{
					Image(uiImage: image)
						.resizable()
						.scaledToFill()
				} else {
					Image(systemName: "person.fill")
						.font(.system(size: size * 0.42, weight: .semibold))
				}
			case .monogram:
				Text(profile.appearance.monogram)
					.font(.system(size: size * 0.36, weight: .semibold))
			case .emoji:
				Text(profile.appearance.emoji)
					.font(.system(size: size * 0.42))
		}
	}
}

enum WidgetProfilePhotoCache {
	static func image(for metadata: ProfilePhotoMetadata) -> UIImage? {
		guard let directory = FileManager.default.containerURL(
			forSecurityApplicationGroupIdentifier: SharedDefaultsStore.suiteName
		)?.appending(path: "ProfileImages", directoryHint: .isDirectory),
			let files = try? FileManager.default.contentsOfDirectory(
				at: directory,
				includingPropertiesForKeys: nil
			),
			let file = files.first(where: {
				$0.lastPathComponent.hasPrefix(
					"\(metadata.checksum)-\(metadata.revision)-"
				)
			}),
			let data = try? Data(contentsOf: file)
		else {
			return nil
		}
		return UIImage(data: data)
	}
}
