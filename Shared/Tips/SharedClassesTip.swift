//
//  SharedClassesTip.swift
//  Timetable
//
//  Created by Adon Omeri on 6/8/2026.
//

import TipKit

struct SharedClassesTip: Tip {
	var image: Image? {
		Image(systemName: "person.2.badge")
	}

	var title: Text {
		Text("Tap a Class To See Details")
	}

	var message: Text? {
		Text("Tap a class to see your shared teacher and other details.")
	}

	var options: [Option] {
		Tips.MaxDisplayCount(1)
	}
}
