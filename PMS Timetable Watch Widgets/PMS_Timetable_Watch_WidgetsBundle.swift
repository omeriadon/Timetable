//
//  PMS_Timetable_Watch_WidgetsBundle.swift
//  PMS Timetable Watch Widgets
//
//  Created by Adon Omeri on 27/4/2026.
//

import SwiftUI
import WidgetKit

@main
struct PMS_Timetable_Watch_WidgetsBundle: WidgetBundle {
	var body: some Widget {
		PMS_Timetable_Watch_Widgets()
		PMS_Timetable_Watch_Widgets_Time_Left()
	}
}
