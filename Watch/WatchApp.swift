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
	@State private var renderedAppFontDesign = Defaults[.accountSettings].appFontDesign
	@State private var appFontTransitionOpacity = 1.0
	@State private var appFontTransitionGeneration = 0

	var body: some Scene {
		WindowGroup {
			ZStack(alignment: .top) {
				WatchSessionRootView(sessionStore: sessionStore)
				WatchStatusBadgeOverlay()
			}
			.id(renderedAppFontDesign)
			.transition(.opacity)
			.opacity(appFontTransitionOpacity)
			.fontDesign(renderedAppFontDesign.swiftUIFontDesign)
			.fontWidth(renderedAppFontDesign.swiftUIFontWidth)
			.onChange(of: accountSettings.appFontDesign) { _, newDesign in
				transitionAppFont(to: newDesign)
			}
			.environment(\.statusBadgeManager, statusBadgeManager)
			.buttonStyle(.haptic)
			.task {
				await configureAndRestore()
			}
		}
	}

	@MainActor
	private func transitionAppFont(to design: AppFontDesign) {
		appFontTransitionGeneration += 1
		let generation = appFontTransitionGeneration

		withAnimation(.linear(duration: 0.05)) {
			appFontTransitionOpacity = 0
		}

		Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(50))
			guard generation == appFontTransitionGeneration else { return }
			renderedAppFontDesign = design
			withAnimation(.linear(duration: 0.05)) {
				appFontTransitionOpacity = 1
			}
		}
	}

	private func configureAndRestore() async {
		_ = ClientIdentityProvider.shared.identity(for: .watchOS)
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
