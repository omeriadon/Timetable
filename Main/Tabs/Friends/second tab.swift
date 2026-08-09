//
//  second tab.swift
//  Timetable
//
//  Created by Adon Omeri on 9/8/2026.
//

import SwiftUI

struct FriendWeek: View {
	let detail: FriendDetail

	var body: some View {
		if let timetable = detail.timetable {
			TimetableWeekGrid(
				subjects: timetable.subjects,
				selectedSlot: nil,
				onSelectSlot: nil
			)
			.frame(maxWidth: .infinity, alignment: .top)
		} else {
			ContentUnavailableView("No Timetable", systemImage: "calendar.badge.exclamationmark")
		}
	}
}
