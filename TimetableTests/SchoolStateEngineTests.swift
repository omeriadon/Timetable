import XCTest

final class SchoolStateEngineTests: XCTestCase {
	private var calendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(identifier: "Australia/Perth")!
		return calendar
	}

	func testWednesdayEndsAfterPeriodFive() throws {
		let periodFive = Subject(
			id: "Science",
			symbol: "atom",
			colour: .init(red: 0, green: 0.5, blue: 1, alpha: 1),
			slots: [Slot(2, 6)]
		)

		let duringPeriodFive = SchoolStateEngine.calculate(
			at: try date(2026, 7, 22, 14, 0),
			subjects: [periodFive],
			calendar: calendar
		)
		guard case let .lesson(lesson) = duringPeriodFive else {
			return XCTFail("Expected period five to be a lesson.")
		}
		XCTAssertEqual(lesson.next, .endOfDay)

		let afterPeriodFive = SchoolStateEngine.calculate(
			at: try date(2026, 7, 22, 14, 32),
			subjects: [periodFive],
			calendar: calendar
		)
		XCTAssertEqual(afterPeriodFive, .afterSchool)
	}

	func testFridayEndsAfterPeriodFive() throws {
		let periodFive = Subject(
			id: "English",
			symbol: "book",
			colour: .init(red: 1, green: 0.5, blue: 0, alpha: 1),
			slots: [Slot(4, 6)]
		)

		XCTAssertEqual(
			SchoolStateEngine.calculate(
				at: try date(2026, 7, 24, 14, 32),
				subjects: [periodFive],
				calendar: calendar
			),
			.afterSchool
		)
	}

	func testMondayRetainsPeriodSix() throws {
		let periodSix = Subject(
			id: "Maths",
			symbol: "function",
			colour: .init(red: 0.5, green: 0, blue: 1, alpha: 1),
			slots: [Slot(0, 7)]
		)

		let state = SchoolStateEngine.calculate(
			at: try date(2026, 7, 20, 14, 40),
			subjects: [periodSix],
			calendar: calendar
		)
		guard case let .lesson(lesson) = state else {
			return XCTFail("Expected period six to remain active on Monday.")
		}
		XCTAssertEqual(lesson.subject.id, "Maths")
	}

	private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) throws -> Date {
		try XCTUnwrap(calendar.date(from: DateComponents(
			year: year,
			month: month,
			day: day,
			hour: hour,
			minute: minute
		)))
	}
}
