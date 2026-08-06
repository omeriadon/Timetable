//
//  WeekTapFriendTip.swift
//  Timetable
//
//  Created by Adon Omeri on 6/8/2026.
//

import TipKit

struct WeekTapFriendTip: Tip {
	@Parameter
	static var isVisible: Bool = false

	var image: Image? {
		Image(systemName: "person.badge.clock")
	}

	var title: Text {
		Text("Tap a Friend To See Details")
	}

	var message: Text? {
		Text("Tap each friend to show their classroom and teacher.")
	}

	var rules: [Rule] {
		#Rule(Self.$isVisible) { $0 == true }
	}

	var options: [Option] {
		Tips.MaxDisplayCount(1)
	}
}
