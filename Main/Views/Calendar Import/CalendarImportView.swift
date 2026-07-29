//
//   CalendarImportView.swift
//   Main
//
//   Created by Adon Omeri on 27/4/2026.
//

import Defaults
import EventKit
import SwiftUI

struct CalendarImportView: View {
	@Environment(\.dismiss) var dismiss
	var dismissesWhenFinished = true
	var completion: ((Bool) -> Void)?

	@Default(.timetable) var subjects

	@State private var calendarImportStatus = CalendarImportStatus.loading
	@State private var calendarImportStep = CalendarImportStep.checkingAuthorisation
	@State private var errorResetTask: Task<Void, Never>?

	var body: some View {
		VStack(spacing: 14) {
			ZStack {
				switch calendarImportStatus {
					case .loading:
						Image(systemName: "calendar.badge.clock")
							.symbolEffect(.breathe)
							.transition(.blurReplace)
					case .success:
						Image(systemName: "checkmark.circle")
							.foregroundStyle(.green)
							.transition(.blurReplace)
					case .error:
						Image(systemName: "exclamationmark.triangle.fill")
							.transition(.blurReplace)
				}
			}
			.font(.largeTitle.scaled(by: 1.5))

			ZStack {
				switch calendarImportStatus {
					case .loading:
						Text("Importing timetable...")
							.transition(.blurReplace)
					case .success:
						VStack {
							Text("Import complete")
							Text("You can change subjects, teachers and classrooms in settings if they have issues.")
								.font(.body)
						}
						.padding(.bottom, 20)
						.transition(.blurReplace)
					case .error:
						Text("Import failed")
							.transition(.blurReplace)
				}
			}
			.font(.title2.scaled(by: 1.2))

			Text(calendarImportStep.text)
				.contentTransition(.numericText())

			HStack(alignment: .center) {
				Text("\(calendarImportStep.progress)")
					.contentTransition(.numericText())

				Gauge(
					value: Double(calendarImportStep.progress),
					in: 0 ... Double(calendarImportStep.total)
				) {
					Text("")
				} currentValueLabel: {
					Text("")
				} minimumValueLabel: {
					Text("")
				} maximumValueLabel: {
					Text("")
				}

				Text("\(calendarImportStep.total)")
			}

			if case .error = calendarImportStatus {
				if !dismissesWhenFinished {
					Button("Try Again", systemImage: "arrow.clockwise") {
						beginImportAttempt()
						Task { await performCalendarImport() }
					}
					.buttonStyle(.glassProminent)
				}
			}
		}
		.animation(.easeInOut, value: calendarImportStep)
		.task {
			beginImportAttempt()
			await performCalendarImport()
		}
		.onDisappear {
			errorResetTask?.cancel()
		}
		.ignoresSafeArea()
		.padding([.horizontal], 32)
		.monospaced()
		.presentationDetents(dismissesWhenFinished ? [.fraction(0.4)] : [.large])
		.interactiveDismissDisabled()
		.presentationDragIndicator(.hidden)
	}

	func moveForward(to step: CalendarImportStep) {
		calendarImportStep = step
	}

	func errorAndExit(_ error: String) {
		calendarImportStep = .error(error)
		calendarImportStatus = .error
		completion?(false)
		scheduleErrorReset(for: error)
		Task {
			PrintError("[iOS] error: \(error)")
			if dismissesWhenFinished {
				try? await Task.sleep(for: .seconds(2))
				dismiss()
			}
		}
	}

	func beginImportAttempt() {
		errorResetTask?.cancel()
		errorResetTask = nil
		calendarImportStatus = .loading
		calendarImportStep = .checkingAuthorisation
	}

	func scheduleErrorReset(for error: String) {
		errorResetTask?.cancel()
		errorResetTask = Task {
			try? await Task.sleep(for: .seconds(4))
			guard !Task.isCancelled else {
				return
			}
			guard case .error = calendarImportStatus, calendarImportStep == .error(error) else {
				return
			}
			calendarImportStatus = .loading
			calendarImportStep = .checkingAuthorisation
		}
	}

	func performCalendarImport() async {
		do {
			Print("[iOS] Calendar Import: Starting authorization check...")
			moveForward(to: .checkingAuthorisation)

			let eventStore = EKEventStore()

			Print("[iOS] Calendar Import: Requesting calendar access...")
			moveForward(to: .requestionCalendarAccess)

			let authorized = try await eventStore.requestFullAccessToEvents()

			guard authorized else {
				errorAndExit("Calendar access denied")
				return
			}

			Print("[iOS] Calendar Import: Searching for Compass calendar...")
			moveForward(to: .findingCalendar)

			guard let calendar = eventStore.calendars(for: .event).first(where: {
				$0.title.range(of: "Compass", options: .caseInsensitive) != nil
			}) else {
				errorAndExit("Compass calendar not found")
				return
			}

			Print("[iOS] Calendar Import: Fetching events...")
			moveForward(to: .fetchingEvents)

			let events = try await fetchCompassEvents(from: eventStore, calendar: calendar)

			Print("[iOS] Calendar Import: Matching events to time slots...")
			moveForward(to: .matchingEvents)

			let importedSubjects = try await matchEventsToTimeSlots(events)

			Print("[iOS] Calendar Import: Processing subjects...")
			moveForward(to: .processingSubjects)
			let translatedSubjects = translateSubjects(importedSubjects)

			Print("[iOS] Calendar Import: Validating...")
			moveForward(to: .finalising)

			let updatedSubjects = translatedSubjects
				.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
				.filter { !$0.slots.isEmpty }
			subjects = try await ServerSyncCoordinator.shared.saveOwnerTimetable(updatedSubjects)

			moveForward(to: .done)
			Print("[iOS] Calendar Import: Success!")
			calendarImportStatus = .success
			completion?(true)
			if dismissesWhenFinished {
				try? await Task.sleep(for: .seconds(2))
				dismiss()
				calendarImportStatus = .loading
			}

		} catch {
			errorAndExit(error.localizedDescription)
		}
	}
}

#Preview {
	Color.gray
		.ignoresSafeArea()
		.sheet(isPresented: .constant(true)) {
			CalendarImportView()
		}
}
