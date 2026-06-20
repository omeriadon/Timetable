//
//  Calendar Import Supporting.swift
//  Timetable
//
//  Created by Adon Omeri on 19/6/2026.
//

import EventKit
import Foundation

struct SlotConflict {
	let slot: Slot
	let firstSubjectName: String
	let secondSubjectName: String
}

enum EditorRequest {
	case allSubjectes(focus: String?)
	case emptySlot(EditableSlot)
}

enum CalendarImportStatus {
	case loading
	case success
	case error
}

// MARK: - fetchCompassEvents

func fetchCompassEvents(from store: EKEventStore, calendar: EKCalendar) async throws -> [EKEvent] {
	let startDate = calculateNextMonday()
	let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: startDate) ?? startDate

	let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
	let events = store.events(matching: predicate)

	print("[iOS] Fetched \(events.count) events from Compass calendar")
	return events
}

// MARK: - calculateNextMonday

func calculateNextMonday() -> Date {
	let calendar = Calendar.current
	let now = Date()
	let components = calendar.dateComponents([.weekday], from: now)

	let daysUntilMonday = (9 - (components.weekday ?? 0)) % 7
	let nextMonday = calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 1 : daysUntilMonday, to: now) ?? now

	return calendar.startOfDay(for: nextMonday)
}

// MARK: - translateSubjectes

func
translateSubjects(_ subjects: [Subject]) -> [Subject] {
	var result: [Subject] = []

	for c in subjects {
		result.append(
			Subject(
				id: translateTitle(c.id),
				symbol: c.symbol,
				colour: c.colour,
				slots: c.slots
			)
		)
	}

	return result
}

// MARK: - matchEventsToTimeSlots

func matchEventsToTimeSlots(_ events: [EKEvent]) async throws -> [Subject] {
	struct SlotWindow {
		let session: Int
		let startHour: Int
		let startMinute: Int
		let endHour: Int
		let endMinute: Int
	}

	let timeSlots: [SlotWindow] = [
		.init(session: 0, startHour: 8, startMinute: 50, endHour: 9, endMinute: 48),
		.init(session: 1, startHour: 9, startMinute: 48, endHour: 10, endMinute: 46),
		.init(session: 3, startHour: 11, startMinute: 8, endHour: 12, endMinute: 6),
		.init(session: 4, startHour: 12, startMinute: 6, endHour: 13, endMinute: 4),
		.init(session: 6, startHour: 13, startMinute: 34, endHour: 14, endMinute: 32),
		.init(session: 7, startHour: 14, startMinute: 32, endHour: 15, endMinute: 30),
	]

	let calendar = Calendar.current
	var subjectMap: [String: (color: RGBAColor, symbol: String, slots: [Slot])] = [:]

	for event in events {
		guard
			let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines),
			!title.isEmpty
		else { continue }

		let weekday = calendar.component(.weekday, from: event.startDate)
		guard (2 ... 6).contains(weekday) else { continue } // Mon...Fri

		let day = weekday - 2 // Mon = 0, Tue = 1, ..., Fri = 4
		let dayStart = calendar.startOfDay(for: event.startDate)

		guard let matchedSlot = timeSlots.first(where: { slot in
			guard
				let slotStart = calendar.date(
					bySettingHour: slot.startHour,
					minute: slot.startMinute,
					second: 0,
					of: dayStart
				),
				let slotEnd = calendar.date(
					bySettingHour: slot.endHour,
					minute: slot.endMinute,
					second: 0,
					of: dayStart
				)
			else { return false }

			return event.startDate < slotEnd && event.endDate > slotStart
		}) else {
			continue
		}

		if subjectMap[title] == nil {
			let randomColor = RGBAColor(
				color: AvailableColors.allCases.randomElement()!.SwiftUIColor
			)

			subjectMap[title] = (
				color: randomColor,
				symbol: translateSymbol(title),
				slots: []
			)
		}

		subjectMap[title]!.slots.append(Slot(day, matchedSlot.session))
	}

	return subjectMap
		.map { name, data in
			Subject(
				id: name,
				symbol: data.symbol,
				colour: data.color,
				slots: Array(Set(data.slots)).sorted {
					$0.day == $1.day ? $0.session < $1.session : $0.day < $1.day
				}
			)
		}
		.sorted { $0.id < $1.id }
}

// MARK: - CalendarImportStep

enum CalendarImportStep: Equatable {
	case checkingAuthorisation
	case requestionCalendarAccess
	case findingCalendar
	case fetchingEvents
	case matchingEvents
	case processingSubjects
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
			case .processingSubjects:
				6
			case .finalising:
				7
			case .done:
				8
			case .error:
				total
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
			case .processingSubjects:
				"Translating titles..."
			case .finalising:
				"Finalising..."
			case .done:
				"Calendar Imported"
			case let .error(t):
				"Error: \(t)"
		}
	}
}

// MARK: - symbols

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

// MARK: - translateSymbol

func translateSymbol(_ original: String) -> String {
	let lower = original.uppercased()

	switch true {
		case lower.contains("DS"):
			return "graduationcap"

		case lower.contains("AEMAM"):
			return "radicand.squareroot"

		case lower.contains("AEPHY"):
			return "atom"

		case lower.contains("AEEST"):
			return "building.columns"

		case lower.contains("AECSC"):
			return "laptopcomputer"

		case lower.contains("ADV"):
			return "person.3"

		case lower.contains("AEPAE"):
			return "brain"

		case lower.contains("AEHBY"):
			return "brain.head.profile"

		case lower.contains("AEENG"):
			return "textformat.characters"

		case lower.contains("AEMAS"):
			return "function"

		case lower.contains("MUSOS"):
			return "music.note"

		case lower.contains("AECHE"):
			return "testtube.2"

		case lower.contains("AEISL"):
			return "character.book.closed"

		case lower.contains("AEFSL1"):
			return "character.book.closed"

		case lower.contains("AELIT"):
			return "books.vertical"

		case lower.contains("AEBLY"):
			return "leaf"

		case lower.contains("MUP"):
			return "mouth"

		default:
			return symbols.randomElement()!
	}
}

// MARK: - translateTitle

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

		case lower.contains("AEFSL1"):
			return "French"

		case lower.contains("AECHE"):
			return "Chemistry"

		case lower.contains("AEHBY"):
			return "Human Bio"

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
