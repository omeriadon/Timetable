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
		#if os(macOS)
			UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
		#endif
	}

	#if os(iOS)
		@UIApplicationDelegateAdaptor(MobileAppDelegate.self) private var mobileAppDelegate
	#endif

	var body: some Scene {
		WindowGroup {
			Group {
				#if os(macOS)
					switch sessionStore.state {
						case .signedOut:
						MacSignInGateView()
						case .restoring:
						ProgressView("Restoring Account…")
						case .authenticated:
						NonAuthoritativeRootView(expanded: $expanded)
					}
				#else
					ZStack {
						switch sessionStore.state {
							case .signedOut:
								ZStack {
									if hasCompletedOnboarding {
										IOSSignInGateView()
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
								if Platform.current == .iPadOS {
									NonAuthoritativeRootView(expanded: $expanded)
										.transition(.blurReplace)
								} else {
									ContentView(expanded: $expanded)
										.transition(.blurReplace)
								}
						}
					}
					.animation(.easeInOut, value: sessionStore.state)
				#endif
			}
			.onOpenURL { url in
				handleIncomingURL(url)
			}
			.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
				guard let url = activity.webpageURL else { return }
				handleIncomingURL(url)
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
				await openSharedTimetableIfPossible()
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
				Platform.current == .iOS
					&& !hasCompletedOnboarding
			)) {
				OnboardingView()
					.interactiveDismissDisabled()
			}
			#endif // os(iOS)
			.onChange(of: scenePhase) { _, phase in
				guard phase == .active else { return }
				Task {
					await openSharedTimetableIfPossible()
					await MessageImportReconciliationService.reconcile()
				}
			}
			.monospaced()
			.environment(\.statusBadgeManager, statusBadgeManager)
			.buttonStyle(.haptic)
			#if os(macOS)
				.onChange(of: expanded) { _, newValue in
					resizeWindow(expanded: newValue)
				}
				.frame(width: 700)
				.frame(minHeight: 475, idealHeight: 475, maxHeight: 750)
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
		.windowResizability(.contentSize)

		#if os(macOS)
			.commands {
				CommandGroup(after: .appSettings) {
					Button("Settings…") { NotificationCenter.default.post(name: .openSettingsTab, object: nil) }
						.keyboardShortcut(",", modifiers: .command)
				}
			}
		#endif
	}

	@MainActor
	private func handleIncomingURL(_ url: URL) {
		if url.scheme == "https", url.host == TimetableShareURL.host {
			if let locator = TimetableShareURL.locator(from: url) {
				queueSharedTimetable(locator)
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
			queueSharedTimetable(locator)
			return
		}
		guard let destination = TimetableDeepLink(url: url) else { return }
		NotificationCenter.default.post(name: .openTimetableDestination, object: destination)
	}

	@MainActor
	private func queueSharedTimetable(_ locator: String) {
		if isOwnerShareLink(locator) {
			NotificationCenter.default.post(
				name: .openTimetableDestination,
				object: TimetableDeepLink.timetable(id: nil)
			)
			StatusBadgeManager.shared.addBadge(
				id: UUID(),
				title: "Opened your timetable",
				priority: 3,
				view: .success
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
			await openSharedTimetableIfPossible()
		}
	}

	@MainActor
	private func openSharedTimetableIfPossible() async {
		guard SessionStore.shared.isAuthenticated,
		      let locator = pendingSharedTimetableLocator
		else { return }

		do {
			let timetable = try await ReceivedTimetableSyncService.shared.importTimetable(locator: locator)
			var locators = Defaults[.pendingMessageTimetableLocators]
			locators.removeAll { $0 == locator }
			Defaults[.pendingMessageTimetableLocators] = locators
			pendingSharedTimetableLocator = nil
			NotificationCenter.default.post(
				name: .openTimetableDestination,
				object: TimetableDeepLink.timetable(id: timetable.id)
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

	#if os(macOS)
		private func resizeWindow(expanded: WindowMode) {
			guard let window = NSApplication.shared.windows.first else { return }

			var newSize: NSSize {
				switch expanded {
					case .none:
						NSSize(width: 700, height: 528)
					case .comparison:
						NSSize(width: 700, height: 750)
					case .settings:
						NSSize(width: 700, height: 650)
				}
			}

			let currentFrame = window.frame

			let deltaHeight = newSize.height - currentFrame.height
			let newOrigin = NSPoint(
				x: currentFrame.origin.x,
				y: currentFrame.origin.y - deltaHeight
			)

			let newFrame = NSRect(
				origin: newOrigin,
				size: newSize
			)

			window.styleMask.remove(.resizable)
			window.styleMask.remove(.fullScreen)

			window.collectionBehavior.remove(.fullScreenPrimary)
			window.collectionBehavior.remove(.fullScreenAuxiliary)
			window.collectionBehavior.insert(.fullScreenNone)

			NSAnimationContext.runAnimationGroup { context in
				context.duration = 0.25
				window.animator().setFrame(newFrame, display: true)
			}
		}
	#endif // os(macOS)
}

#if os(macOS)
	private struct MacSignInGateView: View {
		var body: some View {
			Color.clear
				.sheet(isPresented: .constant(true)) {
					VStack(spacing: 20) {
						Text("Sign In Required").font(.title2.bold())
						Text("Sign in to view your timetable on this Mac.").foregroundStyle(.secondary)

						AccountAuthenticationView()
					}
					.frame(width: 520, height: 580, alignment: .center)
					.padding(30)
					.interactiveDismissDisabled()
				}
		}
	}
#endif // os(macOS)

#if os(iOS)
	private struct IOSSignInGateView: View {
		@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding
		@Default(.onboardingPageID) private var onboardingPageID

		var body: some View {
			NavigationStack {
				ZStack {
					OnboardingBackground(currentPageID: "splash")

					ScrollView {
						AccountAuthenticationView(allowsSignUp: false)
					}
					.scrollBounceBehavior(.basedOnSize)
					.scrollEdgeEffectStyle(.none, for: .vertical)
				}
				.scrollEdgeEffect(offset: 0.8)
				.safeAreaBar(edge: .top, alignment: .center, spacing: 10) {
					Text("Sign in to use Timetable")
						.font(.title)
						.bold()
						.lineLimit(3)
				}
				.safeAreaBar(edge: .bottom) {
					Button("Create an Account") {
						onboardingPageID = ""
						hasCompletedOnboarding = false
					}
					.buttonStyle(.glassProminent)
					.controlSize(.large)
					.buttonSizing(.flexible)
					.padding(.horizontal, 20)
				}
			}
		}
	}
#endif // os(iOS)
