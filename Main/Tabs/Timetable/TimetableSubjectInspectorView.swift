import Defaults
import SwiftUI

struct TimetableSubjectInspectorView: View {
	let subjectID: String
	let slot: Slot?

	@Default(.timetable) private var ownerSubjects

	var body: some View {
		if let subject {
			ScrollView {
				VStack(spacing: 16) {
					SubjectContextPopover(owner: "You", subject: subject)
					TimetableComparison(selectedSlot: resolvedSlot, subject: subject)
				}
				.padding()
			}
			.appNavigationTitle(subject.id)
		} else {
			ContentUnavailableView("Subject Unavailable", systemImage: "calendar.badge.exclamationmark")
		}
	}

	private var subject: Subject? {
		ownerSubjects.first(where: { $0.id == subjectID })
	}

	private var resolvedSlot: Slot? {
		slot ?? subject?.slots.first
	}
}
