//
//  WeekTapSlotTip.swift
//  Timetable
//
//  Created by Adon Omeri on 6/8/2026.
//

import TipKit

struct WeekTapSlotTip: Tip {
	var image: Image? {
		Image(systemName: "calendar.and.person")
	}

	var title: Text {
		Text("Tap a Slot To See Friends")
	}

	var message: Text? {
		Text("Tap each slot in the week view to show your classroom, teacher, and what your friends have now.")
	}

	var options: [Option] {
		Tips.MaxDisplayCount(1)
	}
}
