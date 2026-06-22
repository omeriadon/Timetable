//
//  SharedWidgetBundle.swift
//  Watch Widget
//
//  Created by Adon Omeri on 15/6/2026.
//

import SwiftUI
import WidgetKit

@WidgetBundleBuilder
func SharedWidgetBundle() -> some Widget {
	WeeklyScheduleWidget()
	TimeLeftWidget()
}
