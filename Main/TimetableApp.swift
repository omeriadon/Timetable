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
	import WindowOverlay
#endif
import Defaults
import Foundation
import SwiftUI
import TipKit

struct ImportResult: Equatable {
	let success: Bool
	let message: String
}

enum WindowMode: Int, Equatable, Identifiable {
	var id: Int {
		rawValue
	}

	case none = 1
	case comparison = 2
	case settings = 3
}

@main
struct TimetableApp: App {
	@State var expanded: WindowMode = .none
	@Environment(\.scenePhase) private var scenePhase

	@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding
	#if os(iOS)
		@State private var launchIllusionVisible = true
	#endif

	@State private var sessionStore = SessionStore.shared
	@State private var statusBadgeManager = StatusBadgeManager.shared
	@State private var pendingSharedTimetableLocator: String?

	#if os(macOS)
		@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	#endif

	init() {
		#if DEBUG
			try? Tips.resetDatastore()
		#endif
		try? Tips.configure([
			.datastoreLocation(.applicationDefault),
		])

		#if os(macOS)
			UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
		#endif
	}

	#if os(iOS)
		@UIApplicationDelegateAdaptor(MobileAppDelegate.self) private var mobileAppDelegate
	#endif

	var body: some Scene {
		WindowGroup {
			AppRouterHost { router in
				Group {
					#if os(macOS)
						switch sessionStore.state {
							case .signedOut:
							MainPlatformAuthenticationView()
							case .restoring:
							ProgressView("Restoring Account…")
							case .authenticated:
							AdaptiveAppShell(expanded: $expanded)
						}
					#else
						ZStack {
							switch sessionStore.state {
								case .signedOut:
									ZStack {
										if Platform.current == .iPadOS || hasCompletedOnboarding {
											MainPlatformAuthenticationView()
												.transition(.blurReplace)
										} else {
											Color.clear
												.transition(.blurReplace)
										}
									}
									.animation(.easeInOut, value: hasCompletedOnboarding)

								case .restoring:
									ProgressView("Restoring Account…")
										.transition(.blurReplace)

								case .authenticated:
									AdaptiveAppShell(expanded: $expanded)
										.transition(.blurReplace)
							}
						}
						.animation(.easeInOut, value: sessionStore.state)
					#endif
				}
				.onOpenURL { url in
					handleIncomingURL(url, router: router)
				}
				.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
					guard let url = activity.webpageURL else { return }
					handleIncomingURL(url, router: router)
				}
				#if os(iOS)
				.windowOverlay(isPresented: true, disableSafeArea: false) {
					StatusBadgeOverlay()
						.zIndex(9_999_999)
				}
				#endif // os(iOS)
				.task {
					NetworkManager.shared.configureFeedback { StatusBadgeManager.shared.present(networkError: $0) }
					sessionStore.configureAccountBootstrap {
						try await AccountBootstrapService.shared.bootstrap()
					}
					sessionStore.configureDeviceLifecycle {
						await NotificationRegistrationService.shared.uploadPendingToken()
						#if os(iOS)
							if Platform.current == .iOS {
								await LiveActivityRegistrationService.shared.startObserving()
							}
							PhoneWatchSyncBridge.shared.sendAuthenticatedStateIfPossible()
						#endif // os(iOS)
					} signingOut: {
						#if os(iOS)
							PhoneWatchSyncBridge.shared.sendSignedOutStateIfPossible()
							await LiveActivityRegistrationService.shared.removeLiveActivityToken()
						#endif
						await NotificationRegistrationService.shared.removeServerRegistration()
					}
					_ = ClientIdentityProvider.shared.identity()
					await indexEntities()
					await sessionStore.restore()
					await openSharedTimetableIfPossible(router: router)
					await MessageImportReconciliationService.reconcile()

					await NotificationRegistrationService.shared.requestRemoteRegistration()

					#if os(iOS)
						if Platform.current == .iOS {
							await LiveActivityRegistrationService.shared.startObserving()
						}

						try? await ShaderLibrary.compileStickerShaders()
					#endif
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
					Task {
						await openSharedTimetableIfPossible(router: router)
						await MessageImportReconciliationService.reconcile()
					}
				}
				.onChange(of: sessionStore.state) { _, state in
					guard case .authenticated = state else { return }
					if let route = router.resumePendingExternalRoute() {
						NotificationCenter.default.post(
							name: .openTimetableDestination,
							object: route
						)
					}
					Task {
						await openSharedTimetableIfPossible(router: router)
					}
				}
				.monospaced()
				.environment(\.statusBadgeManager, statusBadgeManager)
				.buttonStyle(.haptic)
				#if os(macOS)
					.frame(minWidth: 800, minHeight: 600)
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

		#if os(macOS)
		.commands {
			CommandMenu("Navigate") {
				Button("Timetable", systemImage: "calendar.day.timeline.left") {
					selectRoot(.timetable)
				}
				.keyboardShortcut("1", modifiers: .command)

				Button("Friends", systemImage: "person.2") {
					selectRoot(.friends)
				}
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

			CommandGroup(after: .appSettings) {
				Button("Settings…") { NotificationCenter.default.post(name: .openSettingsTab, object: nil) }
					.keyboardShortcut(",", modifiers: .command)
			}
		}
		#endif
	}

	private func selectRoot(_ destination: AppRootDestination) {
		NotificationCenter.default.post(name: .selectAppRoot, object: destination)
	}

	@MainActor
	private func handleIncomingURL(_ url: URL, router: AppRouter) {
		if url.scheme == "https", url.host == TimetableShareURL.host {
			if let locator = TimetableShareURL.locator(from: url) {
				queueSharedTimetable(locator, router: router)
			} else {
				StatusBadgeManager.shared.addBadge(
					id: UUID(),
					title: "Invalid timetable link",
					secondaryText: "This link does not identify a timetable.",
					priority: 4,
					view: .error
				)
			}
			return
		}
		if let locator = TimetableShareURL.locator(fromFallbackURL: url) {
			queueSharedTimetable(locator, router: router)
			return
		}
		guard let route = AppRoute(url: url) else { return }
		if sessionStore.isAuthenticated {
			router.navigate(to: route)
		} else {
			router.deferExternalRoute(route)
		}
		NotificationCenter.default.post(name: .openTimetableDestination, object: route)
	}

	@MainActor
	private func queueSharedTimetable(_ locator: String, router: AppRouter) {
		if isOwnerShareLink(locator) {
			router.navigate(to: .timetable(.root))
			NotificationCenter.default.post(
				name: .openTimetableDestination,
				object: AppRoute.timetable(.root)
			)
			StatusBadgeManager.shared.addBadge(
				id: UUID(),
				title: "Imported your own timetable",
				priority: 3,
				view: .info
			)
			return
		}

		pendingSharedTimetableLocator = locator
		var locators = Defaults[.pendingMessageTimetableLocators]
		if !locators.contains(locator) {
			locators.append(locator)
			Defaults[.pendingMessageTimetableLocators] = locators
		}

		Task {
			await openSharedTimetableIfPossible(router: router)
		}
	}

	@MainActor
	private func openSharedTimetableIfPossible(router: AppRouter? = nil) async {
		guard SessionStore.shared.isAuthenticated,
		      let locator = pendingSharedTimetableLocator
		else { return }

		do {
			let timetable = try await ReceivedTimetableSyncService.shared.importTimetable(locator: locator)
			var locators = Defaults[.pendingMessageTimetableLocators]
			locators.removeAll { $0 == locator }
			Defaults[.pendingMessageTimetableLocators] = locators
			pendingSharedTimetableLocator = nil
			let route = AppRoute.timetable(.received(id: timetable.id))
			router?.navigate(to: route)
			NotificationCenter.default.post(
				name: .openTimetableDestination,
				object: route
			)
			StatusBadgeManager.shared.addBadge(
				id: UUID(),
				title: "Opened shared timetable",
				priority: 3,
				view: .success
			)
		} catch let error as NetworkError {
			guard case let .server(statusCode, _) = error, statusCode == 404 else { return }
			clearQueuedSharedTimetable(locator)
			StatusBadgeManager.shared.addBadge(
				id: UUID(),
				title: "Invalid timetable link",
				secondaryText: "This timetable is unavailable.",
				priority: 4,
				view: .error
			)
		} catch {
			// Keep the locator queued for the next authenticated foreground pass.
		}
	}

	@MainActor
	private func isOwnerShareLink(_ locator: String) -> Bool {
		if UUID(uuidString: Defaults[.ownerTimetableID])?.uuidString.caseInsensitiveCompare(locator) == .orderedSame {
			return true
		}
		let alias = Defaults[.ownerTimetableShareAlias]
		return !alias.isEmpty && TimetableShareAliasValidator.canonicalize(alias) == TimetableShareAliasValidator.canonicalize(locator)
	}

	@MainActor
	private func clearQueuedSharedTimetable(_ locator: String) {
		var locators = Defaults[.pendingMessageTimetableLocators]
		locators.removeAll { $0 == locator }
		Defaults[.pendingMessageTimetableLocators] = locators
		pendingSharedTimetableLocator = nil
	}
}
