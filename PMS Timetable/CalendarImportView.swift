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
							.symbolEffect(.breathe)
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
			let translatedClasses = translateClasses(importedClasses)

			print("[iOS] Calendar Import: Validating...")
			await moveForward(to: .finalising)

			classes = translatedClasses

			await moveForward(to: .done)
			print("[iOS] Calendar Import: Success!")
			calendarImportStatus = .success
			try? await Task.sleep(nanoseconds: 2_000_000_000)
			dismiss()
			calendarImportStatus = .loading

		} catch {
			errorAndExit(error.localizedDescription)
		}
	}

	func translateClasses(_ classes: [Class]) -> [Class] {
		var result: [Class] = []

		for c in classes {
			let newName = translateTitle(c.id)
			result.append(
				Class(
					id: newName,
					symbol: c.symbol,
					colour: c.colour,
					slots: c.slots
				)
			)
		}

		return result
	}

	func translateTitle(_ original: String) -> String {
		let lower = original.uppercased()

		switch true {
			case lower.contains("DS"):
				return "Directed Study"

			case lower.contains("AEMAM"):
				return "Methods"

			case lower.contains("AEPHY"):
				return "Physics"

			case lower.contains("AEEST"):
				return "Engineering"

			case lower.contains("AECSC"):
				return "Computer Science"

			case lower.contains("ADV"):
				return "Advocacy"

			case lower.contains("AEPAE"):
				return "Philosophy"

			case lower.contains("AEENG"):
				return "English"

			case lower.contains("AEMAS"):
				return "Specialist"

			case lower.contains("MUSOS"):
				return "Music"

			case lower.contains("AECHE"):
				return "Chemistry"

			case lower.contains("AEISL"):
				return "Italian"

			case lower.contains("AELIT"):
				return "Literature"

			case lower.contains("AEBLY"):
				return "Biology"

			case lower.contains("MUP"):
				return "Chorale"

			default:
				return original
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
						let randomColor = RGBAColor(
							color: AvailableColors.allCases
								.randomElement()!.SwiftUIColor
						)

						let symbols: [String] = [
							"pencil.and.scribble",
							"pencil.tip.crop.circle.badge.arrow.forward",
							"trash.slash.fill",
							"folder.badge.plus",
							"folder.fill.badge.gearshape",
							"paperplane",
							"tray.full.fill",
							"externaldrive.badge.minus",
							"externaldrive.fill.badge.person.crop",
							"opticaldiscdrive",
							"xmark.bin.circle.fill",
							"document.badge.arrow.up",
							"arrow.up.document.fill",
							"arrow.trianglehead.2.clockwise.rotate.90.page.on.clipboard",
							"heart.text.clipboard.fill",
							"text.pad.header.badge.clock",
							"calendar.badge.lock",
							"11.calendar",
							"22.calendar",
							"book",
							"book.closed.fill",
							"magazine",
							"bookmark.square.fill",
							"backpack",
							"link",
							"person.2.badge.key.fill",
							"oar.2.crossed.circle",
							"baseball.fill",
							"american.football.professional",
							"rugbyball.circle.fill",
							"cricket.ball.circle.fill",
							"skis",
							"trophy.circle",
							"umbrella.circle.fill",
							"speaker.plus",
							"speaker.wave.1",
							"speaker.trianglebadge.exclamationmark.fill",
							"arrow.up.left.and.down.right.magnifyingglass",
							"shield.lefthalf.filled.trianglebadge.exclamationmark",
							"flag.circle.fill",
							"flag.pattern.checkered.circle.fill",
							"bell.circle",
							"bell.badge.waveform.slash.fill",
							"tag.circle",
							"flashlight.on.fill",
							"camera.shutter.button.fill",
							"gearshape.fill",
							"bag.badge.plus",
							"cart.fill.badge.plus",
							"creditcard.circle",
							"wand.and.outline",
							"dial.medium.fill",
							"gauge.with.dots.needle.50percent",
							"die.face.2",
							"pianokeys.inverse",
							"hammer.fill",
							"scroll.fill",
							"printer.fill",
							"faxmachine",
							"case.fill",
							"suitcase.rolling",
							"suitcase.rolling.and.film.circle.fill",
							"puzzlepiece.extension",
							"lightbulb.min.fill",
							"fan.oscillation",
							"fan.badge.arrow.up.and.down.and.arrow.left.and.right.fill",
							"lamp.table",
							"light.recessed.3.fill",
							"chandelier",
							"light.beacon.min.fill",
							"door.left.hand.open",
							"door.garage.closed.trianglebadge.exclamationmark",
							"air.purifier",
							"heater.vertical.fill",
							"drop.keypad.rectangle",
							"hifireceiver.fill",
							"laser.burst",
							"bed.double.circle.fill",
							"cabinet",
							"dryer.circle.fill",
							"microwave",
							"sink.fill",
							"tent.2.circle",
							"signpost.left.fill",
							"signpost.and.arrowtriangle.up",
							"lock.fill",
							"lock.rectangle.stack",
							"exclamationmark.lock.fill",
							"lock.rotation",
							"key.radiowaves.forward.slash.fill",
							"pin.square.fill",
							"mappin.and.ellipse",
							"opticaldisc",
							"backpack.sensor.tag.radiowaves.left.and.right.fill",
							"umbrella.sensor.tag.radiowaves.left.and.right",
							"headset",
							"earbuds.in.ear.left",
							"antenna.radiowaves.left.and.right.slash",
							"helmet",
							"fuelpump.exclamationmark.fill",
							"ev.charger.slash.fill",
							"shoe.arrow.trianglehead.up.and.down",
							"batteryblock.fill",
							"batteryblock.stack",
							"minus.plus.batteryblock.stack.arrowtriangle.left.fill",
							"horn.fill",
							"ev.plug.dc.ccs1",
							"medical.thermometer.fill",
							"pills",
							"teddybear",
							"hat.cap",
							"shoe.fill",
							"movieclapper",
							"sunglasses.fill",
							"cube.circle.fill",
							"clock.badge",
							"clock.badge.airplane.fill",
							"gauge.with.needle",
							"gamecontroller.circle.fill",
							"takeoutbag.and.cup.and.straw",
							"fork.knife",
							"scalemass",
							"hourglass",
							"australiandollarsign.bank.building.fill",
							"chineseyuanrenminbisign.bank.building",
							"dongsign.bank.building.fill",
							"hryvniasign.bank.building",
							"malaysianringgitsign.bank.building.fill",
							"pesetasign.bank.building",
							"shekelsign.bank.building.fill",
							"turkishlirasign.bank.building",
							"binoculars.circle",
							"exclamationmark.shield.fill",
						]

						let randomSymbol = symbols[Int.random(in: 0..<symbols.count - 1)]

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
