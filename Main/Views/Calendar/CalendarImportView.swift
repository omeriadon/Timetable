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

	@Default(.timetable) var subjects

	@State var sheetHeight = 0.0

	@State private var calendarImportStatus = CalendarImportStatus.loading
	@State private var calendarImportStep = CalendarImportStep.checkingAuthorisation

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
						Text("Import complete")
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
		}
		.animation(.easeInOut, value: calendarImportStep)
		.task {
			await performCalendarImport()
		}
		.ignoresSafeArea()
		.padding([.horizontal], 32)
		.monospaced()
		.background {
			GeometryReader { proxy in
				Color.clear
					.onAppear {
						sheetHeight = proxy.size.height
					}
			}
		}
		.presentationDetents([.height(sheetHeight)])
		.interactiveDismissDisabled()
		.presentationDragIndicator(.hidden)
	}

	func moveForward(to step: CalendarImportStep) async {
		let delay = Double.random(in: 0.5 ... 1.5)
		try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
		calendarImportStep = step
	}

	func errorAndExit(_ error: String) {
		calendarImportStep = .error(error)
		calendarImportStatus = .error
		Task {
			PrintError("[iOS] error: \(error)")
			try? await Task.sleep(for: .seconds(2))
			dismiss()
		}
	}

	func performCalendarImport() async {
		do {
			Print("[iOS] Calendar Import: Starting authorization check...")
			await moveForward(to: .checkingAuthorisation)

			let eventStore = EKEventStore()

			Print("[iOS] Calendar Import: Requesting calendar access...")
			await moveForward(to: .requestionCalendarAccess)

			let authorized = try await eventStore.requestFullAccessToEvents()

			guard authorized else {
				errorAndExit("Calendar access denied")
				return
			}

			Print("[iOS] Calendar Import: Searching for Compass calendar...")
			await moveForward(to: .findingCalendar)

			guard let calendar = eventStore.calendars(for: .event).first(where: { $0.title.contains("Compass") }) else {
				errorAndExit("Compass calendar not found")
				dismiss()
				calendarImportStatus = .loading
				return
			}

			Print("[iOS] Calendar Import: Fetching events...")
			await moveForward(to: .fetchingEvents)

			let events = try await fetchCompassEvents(from: eventStore, calendar: calendar)

			Print("[iOS] Calendar Import: Matching events to time slots...")
			await moveForward(to: .matchingEvents)

			let importedSubjects = try await matchEventsToTimeSlots(events)

			Print("[iOS] Calendar Import: Processing subjects...")
			await moveForward(to: .processingSubjects)
			let translatedSubjects = translateSubjects(importedSubjects)

			Print("[iOS] Calendar Import: Validating...")
			await moveForward(to: .finalising)

			subjects = translatedSubjects
				.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
				.filter { !$0.slots.isEmpty }
			ServerSyncCoordinator.shared.ownerTimetableChanged()

			await moveForward(to: .done)
			Print("[iOS] Calendar Import: Success!")
			calendarImportStatus = .success
			try? await Task.sleep(for: .seconds(2))
			dismiss()
			calendarImportStatus = .loading

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
