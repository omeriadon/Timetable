//
//  CalendarImportProgressBar.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import EventKit
import SwiftUI

enum CalendarImportStep: Equatable {
	case checkingAuthorisation
	case requestionCalendarAccess
	case findingCalendar
	case fetchingEvents
	case matchingEvents
	case translatingTitles
	case finalising
	case done

	case error(String)

	var total: Int {
		8
	}

	var progress: Int {
		switch self {
			case .checkingAuthorisation:
				1
			case .requestionCalendarAccess:
				2
			case .findingCalendar:
				3
			case .fetchingEvents:
				4
			case .matchingEvents:
				5
			case .translatingTitles:
				6
			case .finalising:
				7
			case .done:
				8
			case .error:
				8
		}
	}

	var text: String {
		switch self {
			case .checkingAuthorisation:
				"Checking authorisation..."
			case .requestionCalendarAccess:
				"Requesting calendar access..."
			case .findingCalendar:
				"Finding calendar..."
			case .fetchingEvents:
				"Fetching events..."
			case .matchingEvents:
				"Matching events..."
			case .translatingTitles:
				"Translating titles..."
			case .finalising:
				"Finalising..."
			case .done:
				"Calendar Imported"
			case .error(let t):
				"Error: \(t)"
		}
	}
}

struct CalendarImportView: View {
	@Environment(\.dismiss) var dismiss

	@Default(.timetable) var classes

	@State var sheetHeight = 0.0

	@State private var calendarImportStatus = CalendarImportStatus.loading
	@State private var calendarImportStep = CalendarImportStep.checkingAuthorisation

	var body: some View {
		VStack(spacing: 14) {
			ZStack {
				switch calendarImportStatus {
					case .loading:
						Image(systemName: "calendar.badge.clock")
							.transition(.blurReplace)
					case .success:
						Image(systemName: "checkmark.circle.fill")
							.transition(.blurReplace)
					case .error:
						Image(systemName: "exclamationmark.triangle.fill")
							.transition(.blurReplace)
				}
			}
			.font(.largeTitle.scaled(by: 1.5))
			.animation(.easeInOut, value: calendarImportStatus)

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
			.animation(.easeInOut, value: calendarImportStatus)

			Text(calendarImportStep.text)
				.contentTransition(.numericText())

			HStack(alignment: .center) {
				Text("\(calendarImportStep.progress)")
					.contentTransition(.numericText())

				Gauge(
					value: Double(calendarImportStep.progress),
					in: 0...Double(calendarImportStep.total)
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
		.padding([.top, .horizontal], 32)
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
		let delay = Double.random(in: 0.5...1.5)
		try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
		calendarImportStep = step
	}

	func errorAndExit(_ error: String) {
		calendarImportStep = .error(error)
		calendarImportStatus = .error
		Task {
			print("[iOS] error: \(error)")
			try? await Task.sleep(for: .seconds(2))
			dismiss()
		}
	}

	func performCalendarImport() async {
		do {
			print("[iOS] Calendar Import: Starting authorization check...")
			await moveForward(to: .checkingAuthorisation)

			let eventStore = EKEventStore()

			print("[iOS] Calendar Import: Requesting calendar access...")
			await moveForward(to: .requestionCalendarAccess)

			let authorized = try await eventStore.requestFullAccessToEvents()

			guard authorized else {
				errorAndExit("Calendar access denied")
				return
			}

			print("[iOS] Calendar Import: Searching for Compass calendar...")
			await moveForward(to: .findingCalendar)

			guard let calendar = eventStore.calendars(for: .event).first(where: { $0.title.contains("Compass") }) else {
				errorAndExit("Compass calendar not found")
				dismiss()
				calendarImportStatus = .loading
				return
			}

			print("[iOS] Calendar Import: Fetching events...")
			await moveForward(to: .fetchingEvents)

			let events = try await fetchCompassEvents(from: eventStore, calendar: calendar)

			print("[iOS] Calendar Import: Matching events to time slots...")
			await moveForward(to: .matchingEvents)

			let importedClasses = try await matchEventsToTimeSlots(events)

			print("[iOS] Calendar Import: Processing titles...")
			await moveForward(to: .translatingTitles)

			print("[iOS] Calendar Import: Validating...")
			await moveForward(to: .finalising)

			classes = importedClasses

			await moveForward(to: .done)
			print("[iOS] Calendar Import: Success!")
			calendarImportStatus = .success
			try? await Task.sleep(nanoseconds: 2_00_000_000)
			dismiss()
			calendarImportStatus = .loading

		} catch {
			errorAndExit(error.localizedDescription)
		}
	}

	func fetchCompassEvents(from store: EKEventStore, calendar: EKCalendar) async throws -> [EKEvent] {
		let startDate = calculateNextMonday()
		let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: startDate) ?? startDate

		let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
		let events = store.events(matching: predicate)

		print("[iOS] Fetched \(events.count) events from Compass calendar")
		return events
	}

	func calculateNextMonday() -> Date {
		let calendar = Calendar.current
		let now = Date()
		let components = calendar.dateComponents([.weekday], from: now)

		let daysUntilMonday = (9 - (components.weekday ?? 0)) % 7
		let nextMonday = calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 1 : daysUntilMonday, to: now) ?? now

		return calendar.startOfDay(for: nextMonday)
	}

	func matchEventsToTimeSlots(_ events: [EKEvent]) async throws -> [Class] {
		let timeSlots = [
			(startHour: 8, startMinute: 50, endHour: 9, endMinute: 48),
			(startHour: 9, startMinute: 48, endHour: 10, endMinute: 46),
			(startHour: 11, startMinute: 8, endHour: 12, endMinute: 6),
			(startHour: 12, startMinute: 6, endHour: 13, endMinute: 4),
			(startHour: 13, startMinute: 34, endHour: 14, endMinute: 32),
			(startHour: 14, startMinute: 32, endHour: 15, endMinute: 30),
		]

		var classMap: [String: (color: RGBAColor, symbol: String, slots: [Slot])] = [:]
		var foundClasses = Set<String>()

		for day in 0..<5 {
			for (sessionIndex, slot) in timeSlots.enumerated() {
				let targetDate = Calendar.current.date(byAdding: .day, value: day, to: calculateNextMonday()) ?? Date()
				guard let slotStart = Calendar.current.date(bySettingHour: slot.startHour, minute: slot.startMinute, second: 0, of: targetDate),
				      let slotEnd = Calendar.current.date(bySettingHour: slot.endHour, minute: slot.endMinute, second: 0, of: targetDate)
				else {
					continue
				}

				let overlappingEvents = events.filter { $0.startDate < slotEnd && $0.endDate > slotStart }
				if let event = overlappingEvents.sorted(by: { $0.startDate < $1.startDate }).first ?? events.first(where: { $0.startDate >= slotStart && $0.startDate < slotEnd }) {
					guard let className = event.title, !className.isEmpty else { continue }
					foundClasses.insert(className)

					if classMap[className] == nil {
						let randomColor = RGBAColor(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1), alpha: 1)
						let randomSymbol = ["book.fill", "pencil.circle.fill", "person.fill", "chart.bar.fill"][Int.random(in: 0..<4)]
						classMap[className] = (color: randomColor, symbol: randomSymbol, slots: [])
					}

					classMap[className]?.slots.append(Slot(day, sessionIndex + 1))
				}
			}
		}

		return classMap.map { name, data in
			Class(id: name, symbol: data.symbol, colour: data.color, slots: data.slots)
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
