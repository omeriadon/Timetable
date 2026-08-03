import Defaults
import SwiftUI

struct TimetableSubjectInspectorView: View {
	let timetableID: String?
	let subjectID: String
	let slot: Slot?

	@Default(.timetable) private var ownerSubjects
	@Default(.receivedTimetables) private var receivedTimetables

	var body: some View {
		if let subject {
			ScrollView {
				VStack(spacing: 16) {
					SubjectContextPopover(owner: ownerName, subject: subject)
					TimetableComparison(selectedSlot: resolvedSlot, subject: subject)
				}
				.padding()
			}
			.appNavigationTitle(subject.id)
		} else {
			ContentUnavailableView("Subject Unavailable", systemImage: "calendar.badge.exclamationmark")
		}
	}

	private var timetable: [Subject] {
		guard let timetableID,
		      let received = receivedTimetables.first(where: { $0.id == timetableID && !$0.isDeleted })
		else {
			return ownerSubjects
		}
		return received.subjects
	}

	private var ownerName: String {
		guard let timetableID,
		      let received = receivedTimetables.first(where: { $0.id == timetableID })
		else {
			return "You"
		}
		return received.sender
	}

	private var subject: Subject? {
		timetable.first(where: { $0.id == subjectID })
	}

	private var resolvedSlot: Slot? {
		slot ?? subject?.slots.first
	}
}
