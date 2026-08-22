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
	let context: OnboardingPageContext

	@State private var clickedImport = false
	@State private var canSkipImport = true
	@State private var errorResetTask: Task<Void, Never>?

	var body: some View {
		ZStack {
			switch clickedImport {
				case false:
					VStack(spacing: 25) {
						Button {
							clickedImport = true
							canSkipImport = false
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
						errorResetTask?.cancel()
						canSkipImport = !succeeded
						context.configure(
							canAdvance: succeeded,
							isWorking: false,
							statusMessage: succeeded ? "Calendar imported." : "Calendar import failed."
						)
						if !succeeded {
							scheduleErrorReset()
						}
					}
					.padding(10)
					.padding(.top, 5)
					.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 30))
					.transition(.blurReplace)
			}

			if canSkipImport {
				Button("Skip Import", systemImage: "forward.end") {
					context.configure(
						canAdvance: true,
						isWorking: false,
						statusMessage: "Calendar import skipped."
					)
				}
				.buttonStyle(.glass)
				.foregroundStyle(.red)
				.controlSize(.small)
				.accessibilityHint("Continues without importing your timetable")
			}
		}
		.onAppear {
			context.isWorking = false
		}
		.onDisappear {
			clickedImport = false
			canSkipImport = true
			errorResetTask?.cancel()
		}
		.animation(.easeInOut, value: clickedImport)
	}

	private func scheduleErrorReset() {
		errorResetTask = Task {
			try? await Task.sleep(for: .seconds(4))
			guard !Task.isCancelled, context.statusMessage == "Calendar import failed." else {
				return
			}
			context.configure(canAdvance: false, statusMessage: nil)
		}
	}
}
