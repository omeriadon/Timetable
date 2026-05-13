//
//  SyncButton.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

struct SyncButton: View {
	let syncStatus: SyncMode
	let isDefaultTimetable: Bool
	let action: () -> Void

	var body: some View {
		// Only show if the timetable has been modified
		if !isDefaultTimetable {
			Button(action: action) {
				ZStack {
					switch syncStatus {
						case .normal:
							Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
								.transition(.blurReplace)
						case .loading:
							ProgressView()
								.transition(.blurReplace)
						case .success:
							Image(systemName: "checkmark")
								.transition(.blurReplace)
						case .error:
							Image(systemName: "exclamationmark.triangle")
								.transition(.blurReplace)
					}
				}
				.foregroundStyle(.white)
				.animation(.easeInOut, value: syncStatus)
			}
			.buttonStyle(.glassProminent)
			// Disables button interaction while syncing
			.disabled(syncStatus == .loading)
		}
	}
}
