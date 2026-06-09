//
//  SyncButton.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

struct SyncButton: View {
	let syncStatus: SyncMode
	let isDefaultTimetable: Bool
	let action: () -> Void

	var body: some View {
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
			.buttonBorderShape(.circle)
			.buttonStyle(.glassProminent)
			.disabled(syncStatus == .loading)
		}
	}
}
