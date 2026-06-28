//
//   SyncButton.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI
import WatchConnectivity

struct SyncButton: View {
	let syncStatus: SyncMode
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			ZStack {
				switch syncStatus {
					case .normal:
						Label("Sync To Watch", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
							.foregroundStyle(.accent)
							.transition(.blurReplace)

					case .loading:
						Label {
							Text("Loading...")
						} icon: {
							ProgressView()
						}
						.transition(.blurReplace)

					case .success:
						Label("Done", systemImage: "checkmark")
							.transition(.blurReplace)

					case .error:
						Label(errorText(), systemImage: "exclamationmark.triangle")
							.transition(.blurReplace)
				}
			}
			.animation(.easeInOut, value: syncStatus)
		}
		.disabled(syncStatus == .loading)
	}

	func errorText() -> String {
		var error = "Error"
		if !WCSession.default.isWatchAppInstalled {
			error = "Watch app not installed"
		}

		return error
	}
}
