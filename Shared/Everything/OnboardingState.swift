import Foundation

enum OnboardingStateLogic {
	static func restoredPageID(savedID: String, currentID: String?, visiblePageIDs: [String]) -> String? {
		if let currentID, visiblePageIDs.contains(currentID) {
			return currentID
		}
		if !savedID.isEmpty, visiblePageIDs.contains(savedID) {
			return savedID
		}
		return visiblePageIDs.first
	}

	static func shouldSkipCalendarImport(isAuthenticated: Bool, bootstrapCompleted: Bool, timetableIsEmpty: Bool) -> Bool {
		isAuthenticated && bootstrapCompleted && !timetableIsEmpty
	}
}
