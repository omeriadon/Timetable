//
//   WatchApp.swift
//   Watch
//
//   Created by Adon Omeri on 26/4/2026.
//

import Defaults
import SwiftUI

@main
struct TimetableWatchApp: App {
	@State private var sessionStore = SessionStore.shared
	@State private var statusBadgeManager = StatusBadgeManager.shared

	var body: some Scene {
		WindowGroup {
			ZStack(alignment: .top) {
				WatchSessionRootView(sessionStore: sessionStore)
				WatchStatusBadgeOverlay()
			}
			.environment(\.statusBadgeManager, statusBadgeManager)
			.task {
				await configureAndRestore()
			}
		}
	}

	private func configureAndRestore() async {
		if Defaults[.installationID].isEmpty {
			Defaults[.installationID] = UUID().uuidString
		}
		SessionStore.shared.configureAccountBootstrap {
			try await WatchAccountBootstrapService.shared.bootstrap()
		}
		NetworkManager.shared.configureFeedback {
			StatusBadgeManager.shared.present(networkError: $0)
		}
		NetworkManager.shared.startMonitoring()
		WatchProvisioningService.shared.activate()
		await SessionStore.shared.restore()
	}
}
