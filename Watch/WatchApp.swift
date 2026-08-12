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
	@Default(.accountSettings) private var accountSettings

	var body: some Scene {
		WindowGroup {
			ZStack {
				WatchAppBackground(background: accountSettings.appBackground)
					.id(accountSettings.appBackground)
					.transition(.opacity)

				ZStack(alignment: .top) {
					WatchSessionRootView(sessionStore: sessionStore)
					WatchStatusBadgeOverlay()
				}
				.fontDesign(accountSettings.appFontDesign.swiftUIFontDesign)
				.fontWidth(accountSettings.appFontDesign.swiftUIFontWidth)
			}
			.animation(.easeInOut(duration: 0.25), value: accountSettings.appBackground)
			.environment(\.statusBadgeManager, statusBadgeManager)
			.buttonStyle(.haptic)
			.task {
				await configureAndRestore()
			}
		}
	}

	private func configureAndRestore() async {
		_ = ClientIdentityProvider.shared.identity(for: .watchOS)
		SessionStore.shared.configureAccountBootstrap {
			try await WatchAccountBootstrapService.shared.bootstrap()
		}
		SessionStore.shared.configureSessionRecovery {
			WatchProvisioningService.shared.requestSessionIfPossible()
		}
		SessionStore.shared.configureDeviceLifecycle {
			await DeviceSynchronizationService.shared.synchronize()
		} signingOut: {
			await DeviceSynchronizationService.shared.remove()
		}
		NetworkManager.shared.configureFeedback {
			StatusBadgeManager.shared.present(networkError: $0)
		}
		NetworkManager.shared.startMonitoring()
		WatchProvisioningService.shared.activate()
		await SessionStore.shared.restore()
	}
}
