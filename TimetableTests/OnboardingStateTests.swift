import XCTest

final class OnboardingStateTests: XCTestCase {
	func testRestoresCurrentPageWhenStillVisible() {
		XCTAssertEqual(
			OnboardingStateLogic.restoredPageID(savedID: "calendar", currentID: "account", visiblePageIDs: ["account", "calendar"]),
			"account"
		)
	}

	func testRestoresPersistedPageWhenCurrentPageWasRemoved() {
		XCTAssertEqual(
			OnboardingStateLogic.restoredPageID(savedID: "calendar-import", currentID: nil, visiblePageIDs: ["account", "calendar-import"]),
			"calendar-import"
		)
		XCTAssertEqual(
			OnboardingStateLogic.restoredPageID(savedID: "removed", currentID: nil, visiblePageIDs: ["account"]),
			"account"
		)
	}

	func testExistingAuthenticatedServerTimetableSkipsImport() {
		XCTAssertTrue(OnboardingStateLogic.shouldSkipCalendarImport(isAuthenticated: true, bootstrapCompleted: true, timetableIsEmpty: false))
		XCTAssertFalse(OnboardingStateLogic.shouldSkipCalendarImport(isAuthenticated: false, bootstrapCompleted: true, timetableIsEmpty: false))
		XCTAssertFalse(OnboardingStateLogic.shouldSkipCalendarImport(isAuthenticated: true, bootstrapCompleted: false, timetableIsEmpty: false))
		XCTAssertFalse(OnboardingStateLogic.shouldSkipCalendarImport(isAuthenticated: true, bootstrapCompleted: true, timetableIsEmpty: true))
	}
}
