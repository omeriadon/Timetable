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

	@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding

	@State private var passManager = TimetablePassManager()
	@State private var sessionStore = SessionStore.shared
	@State private var statusBadgeManager = StatusBadgeManager.shared

	#if os(macOS)
		@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

		init() {
			UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
		}
	#endif // os(macOS)

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
						ContentView(expanded: $expanded)
					}
				#else
					ContentView(expanded: $expanded)
				#endif
			}
			.onOpenURL { url in
				guard url.scheme == "timetable" else { return }
				NotificationCenter.default.post(name: .openTimetableTab, object: nil)
			}
			#if os(iOS)
			.windowOverlay(isPresented: true, disableSafeArea: false) {
				StatusBadgeOverlay()
					.zIndex(9_999_999)
			}
			#else
			.overlay {
						StatusBadgeOverlay()
							.zIndex(9_999_999)
					}
			#endif
					.task {
						NetworkManager.shared.configureFeedback { StatusBadgeManager.shared.present(networkError: $0) }
						passManager.configureProjectionUpload {
							guard sessionStore.isAuthenticated else { return }
							try await ReceivedTimetableSyncService.shared.uploadCurrentProjection()
						}
						sessionStore.configureAccountBootstrap {
							try await AccountBootstrapService.shared.bootstrap()
						}
						sessionStore.configureDeviceLifecycle {
							await NotificationRegistrationService.shared.uploadPendingToken()
							#if os(iOS)
								await LiveActivityRegistrationService.shared.startObserving()
								PhoneWatchSyncBridge.shared.sendAuthenticatedStateIfPossible()
							#endif
						} signingOut: {
							#if os(iOS)
								PhoneWatchSyncBridge.shared.sendSignedOutStateIfPossible()
								await LiveActivityRegistrationService.shared.removeLiveActivityToken()
							#endif
							await NotificationRegistrationService.shared.removeServerRegistration()
						}
						if Defaults[.installationID].isEmpty {
							Defaults[.installationID] = DeviceIDProvider.shared.getDeviceID()
						}
						await indexEntities()
						await sessionStore.restore()

						await NotificationRegistrationService.shared.requestRemoteRegistration()

						#if os(iOS)
							await LiveActivityRegistrationService.shared.startObserving()

							try? await ShaderLibrary.compileStickerShaders()
						#endif
					}
			#if os(iOS)
					.fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
						OnboardingView()
							.interactiveDismissDisabled()
					}
					.environment(\.passManager, passManager)
			#endif // os(iOS)
					.monospaced()
					.environment(\.statusBadgeManager, statusBadgeManager)
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
				.preferredColorScheme(.dark)
			#endif
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

	#if os(macOS)
		private func resizeWindow(expanded: WindowMode) {
			guard let window = NSApplication.shared.windows.first else { return }

			var newSize: NSSize {
				switch expanded {
					case .none:
						NSSize(width: 700, height: 528)
					case .comparison:
						NSSize(width: 700, height: 727)
					case .settings:
						NSSize(width: 700, height: 750)
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
					VStack(spacing: 16) {
						Text("Sign In Required").font(.title2.bold())
						Text("Sign in to view your timetable on this Mac.").foregroundStyle(.secondary)
						AccountAuthenticationView(allowsSignUp: false)
					}
					.padding(30)
					.frame(width: 520, height: 560)
					.interactiveDismissDisabled()
				}
		}
	}
#endif
