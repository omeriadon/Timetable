//
//  OnboardingCalendarImportView.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Defaults
import EventKit
import SwiftUI
import UIKit
import UserNotifications

struct OnboardingCalendarImportView: View {
	@Environment(\.onboardingPageContext) private var context
	@State private var importSucceeded = false

	@State var clickedImport = false

	var body: some View {
		ZStack {
			switch clickedImport {
				case false:
					Button {
						clickedImport = true
					} label: {
						Label("Import Schedule from Compass", systemImage: "square.and.arrow.down")
						Text("You will need to have synced Compass Schedule to Apple Calendar.")
					}
					.font(.title2)
					.controlSize(.extraLarge)
					.transition(.blurReplace)
				case true:
					CalendarImportView(dismissesWhenFinished: false) { succeeded in
						importSucceeded = succeeded
						context.configure(
							canAdvance: succeeded,
							isWorking: false,
							statusMessage: succeeded ? "Calendar imported." : "Calendar import failed."
						)
					}
					.transition(.blurReplace)
			}
		}
		.onAppear {
			context.configure(canAdvance: importSucceeded, isWorking: !importSucceeded)
		}
		.animation(.easeInOut, value: clickedImport)
	}
}
