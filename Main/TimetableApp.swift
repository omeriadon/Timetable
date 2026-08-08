//
//   TimetableApp.swift
//   Main
//
//   Created by Adon Omeri on 25/4/2026.
//

#if os(macOS)
	import AppKit
#else
	import Sticker
#endif
import Defaults
import Foundation
import SwiftUI
import TipKit

struct ImportResult: Equatable {
	let success: Bool
	let message: String
}

@main
struct TimetableApp: App {
	@Environment(\.scenePhase) private var scenePhase

	@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding
	#if os(iOS)
		@State private var launchIllusionVisible = true
	#endif

	@Default(.incomingFriendRequests) private var incomingFriendRequests
	@Default(.accountSettings) private var accountSettings
	@State private var renderedAppFontDesign = Defaults[.accountSettings].appFontDesign
	@State private var appFontTransitionOpacity = 1.0
	@State private var appFontTransitionGeneration = 0

	@State private var sessionStore = SessionStore.shared
	@State private var statusBadgeManager = StatusBadgeManager.shared

	#if os(macOS)
		@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif

	init() {
		#if DEBUG
			try? Tips.resetDatastore()
		#endif
		try? Tips.configure([
			.datastoreLocation(.applicationDefault),
			.displayFrequency(.hourly),
		])

		#if os(macOS)
			UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
		#endif
	}

	@UIApplicationDelegateAdaptor(MobileAppDelegate.self) private var mobileAppDelegate

	var body: some Scene {
		WindowGroup {
			AppRouterHost { router in
				ZStack {
					switch sessionStore.state {
						case .signedOut:
							MainPlatformAuthenticationView()
								.transition(.blurReplace)
						case .restoring:
							ProgressView("Restoring Account…")
								.transition(.blurReplace)
						case .authenticated:
							AdaptiveAppShell()
								.transition(.blurReplace)
					}

					#if os(iOS)
						StatusBadgeOverlay()
							.zIndex(9_999_999)
					#endif
				}
				.animation(.easeInOut, value: sessionStore.state)
				.id(renderedAppFontDesign)
				.transition(.opacity)
				.opacity(appFontTransitionOpacity)
				.onOpenURL { url in
					handleAppRoute(url, router: router)
				}
				.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
					guard let url = activity.webpageURL else { return }
					handleAppRoute(url, router: router)
				}
				.task {
					NetworkManager.shared.configureFeedback { StatusBadgeManager.shared.present(networkError: $0) }
					sessionStore.configureAccountBootstrap {
						try await AccountBootstrapService.shared.bootstrap()
					}
					sessionStore.configureDeviceLifecycle {
						await NotificationRegistrationService.shared.uploadPendingToken()
						#if os(iOS) && !targetEnvironment(macCatalyst)
							if Platform.current == .iOS {
								await LiveActivityRegistrationService.shared.startObserving()
								await LocationStatusService.shared.start()
							}
							PhoneWatchSyncBridge.shared.sendAuthenticatedStateIfPossible()
						#endif
					} signingOut: {
						#if os(iOS) && !targetEnvironment(macCatalyst)
							PhoneWatchSyncBridge.shared.sendSignedOutStateIfPossible()
							await LiveActivityRegistrationService.shared.removeLiveActivityToken()
						#endif
						await NotificationRegistrationService.shared.removeServerRegistration()
					}
					_ = ClientIdentityProvider.shared.identity()
					await indexEntities()
					await sessionStore.restore()
					await NotificationRegistrationService.shared.requestRemoteRegistration()

					#if os(iOS) && !targetEnvironment(macCatalyst)
						if Platform.current == .iOS {
							await LiveActivityRegistrationService.shared.startObserving()
							await LocationStatusService.shared.start()
						}

						try? await ShaderLibrary.compileStickerShaders()
					#endif // os(iOS) && !targetEnvironment(macCatalyst)
				}
				#if os(iOS)
				.fullScreenCover(isPresented: .constant(
					!hasCompletedOnboarding
				)) {
					OnboardingView()
						.interactiveDismissDisabled()
				}
				#endif // os(iOS)
				.onChange(of: scenePhase) { _, phase in
					guard phase == .active else { return }
				}
				.onChange(of: sessionStore.state) { _, state in
					guard case .authenticated = state else { return }
					if let route = router.resumePendingExternalRoute() {
						NotificationCenter.default.post(
							name: .openTimetableDestination,
							object: route
						)
					}
				}
				.fontDesign(renderedAppFontDesign.swiftUIFontDesign)
				.fontWidth(renderedAppFontDesign.swiftUIFontWidth)
				.onChange(of: accountSettings.appFontDesign) { _, newDesign in
					transitionAppFont(to: newDesign)
				}
				.environment(\.statusBadgeManager, statusBadgeManager)
				.buttonStyle(.haptic)
				#if os(macOS)
					.frame(minWidth: 800, minHeight: 600)
					.background {
						CustomMaterialView()
							.ignoresSafeArea()
					}
				#else
					.overlay {
							if launchIllusionVisible {
								LaunchIllusionView {
									launchIllusionVisible = false
								}
								.ignoresSafeArea()
								.allowsHitTesting(false)
							}
						}
				#endif
						.preferredColorScheme(.dark)
			}
		}
		#if os(macOS)
		.defaultSize(width: 1100, height: 720)
		#endif
		.commands {
			CommandMenu("Navigate") {
				Button("Timetable", systemImage: "calendar.day.timeline.left") {
					selectRoot(.timetable)
				}
				.keyboardShortcut("1", modifiers: .command)

				Button("Friends", systemImage: "person.2") {
					selectRoot(.friends)
				}
				.badge(incomingFriendRequests.count)
				.keyboardShortcut("2", modifiers: .command)

				Button("Settings", systemImage: "gear") {
					selectRoot(.settings)
				}
				.keyboardShortcut("3", modifiers: .command)

				Button("Administration", systemImage: "calendar.badge.lock") {
					selectRoot(.administration)
				}
				.keyboardShortcut("4", modifiers: .command)
			}

			CommandGroup(replacing: .appSettings) {
				Button("Settings…") { NotificationCenter.default.post(name: .openSettingsTab, object: nil) }
					.keyboardShortcut(",", modifiers: .command)
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

	private func selectRoot(_ destination: AppRootDestination) {
		NotificationCenter.default.post(name: .selectAppRoot, object: destination)
	}

	@MainActor
	private func handleAppRoute(_ url: URL, router: AppRouter) {
		guard let route = AppRoute(url: url) else { return }
		if sessionStore.isAuthenticated {
			router.navigate(to: route)
		} else {
			router.deferExternalRoute(route)
		}
		NotificationCenter.default.post(name: .openTimetableDestination, object: route)
	}
}
