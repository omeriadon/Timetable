//
//  ActivityAttribute.swift
//  Timetable
//
//  Created by Adon Omeri on 14/5/2026.
//

import ActivityKit
import WidgetKit

struct iPhone_Widget_ExtensionAttributes: ActivityAttributes {
	struct ContentState: Codable, Hashable {
		/// Dynamic stateful properties about your activity go here!
		var emoji: String
	}

	/// Fixed non-changing properties about your activity go here!
	var name: String
}
