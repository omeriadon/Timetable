//
//  Widget Bundle.swift
//  Widget Bundle
//
//  Created by Adon Omeri on 27/4/2026.
//

import SwiftUI
import WidgetKit

@main
struct WidgetsBundle: WidgetBundle {
	var body: some Widget {
		WeeklyScheduleWidget()
		TimeLeftWidget()
	}
}
