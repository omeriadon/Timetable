//
//  TodayTapSubjectTip.swift
//  Timetable
//
//  Created by Adon Omeri on 6/8/2026.
//

import TipKit

struct TodayTapSubjectTip: Tip {
	var image: Image? {
		Image(systemName: "list.bullet.badge.ellipsis")
	}

	var title: Text {
		Text("Tap a Subject To See Details")
	}

	var message: Text? {
		Text("Tap a subject to see your teacher and classroom.")
	}

	var options: [Option] {
		Tips.MaxDisplayCount(1)
	}
}
