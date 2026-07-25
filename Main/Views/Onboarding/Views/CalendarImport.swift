//
//  CalendarImport.swift
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

	@State private var clickedImport = false

	var body: some View {
		ZStack {
			switch clickedImport {
				case false:
					VStack(spacing: 25) {
						Button {
							clickedImport = true
							context.isWorking = true
						} label: {
							VStack {
								Label("Import Schedule from Compass", systemImage: "square.and.arrow.down")
									.font(.title2)
									.multilineTextAlignment(.center)
							}
						}
						.controlSize(.extraLarge)
						.buttonStyle(.glassProminent)

						Text("You will need to have synced Compass Schedule to Apple Calendar.")
							.multilineTextAlignment(.center)
					}
					.transition(.blurReplace)

				case true:
					CalendarImportView(dismissesWhenFinished: false) { succeeded in
						context.configure(
							canAdvance: succeeded,
							isWorking: false,
							statusMessage: succeeded ? "Calendar imported." : "Calendar import failed."
						)
					}
					.padding(10)
					.padding(.top, 5)
					.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 30))
					.transition(.blurReplace)
			}
		}
		.onAppear {
			context.isWorking = false
		}
		.onDisappear {
			clickedImport = false
		}
		.animation(.easeInOut, value: clickedImport)
	}
}
