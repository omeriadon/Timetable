//
//   TimetableApp.swift
//   Main
//
//   Created by Adon Omeri on 25/4/2026.
//

#if os(macOS)
	import AppKit
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

	@Default(.userDisplayName) var userName

	private let cloudSync = CloudStore.shared

	@State private var passManager = TimetablePassManager()
	@State private var sessionStore = SessionStore.shared
	@State private var statusBadgeManager = StatusBadgeManager.shared

	var showNameSheet: Bool {
		userName.isEmpty
	}

	#if os(macOS)
		@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

		init() {
			UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
		}
	#endif // os(macOS)

	#if os(iOS) || os(visionOS)
		@UIApplicationDelegateAdaptor(MobileAppDelegate.self) private var mobileAppDelegate
	#endif

	var body: some Scene {
		WindowGroup {
			ContentView(expanded: $expanded)
				.overlay {
					StatusBadgeOverlay()
				}
				.task {
					passManager.configureProjectionUpload {
						try await ReceivedTimetableSyncService.shared.uploadCurrentProjection()
					}
					sessionStore.configureAccountBootstrap {
						try await AccountBootstrapService.shared.bootstrap()
					}
					if Defaults[.installationID].isEmpty {
						Defaults[.installationID] = DeviceIDProvider.shared.getDeviceID()
					}
					await indexEntities()
					await sessionStore.restore()
					#if os(iOS) || os(visionOS)
						await NotificationRegistrationService.shared.reconcileWithStoredPreference()
					#endif
				}
			#if os(iOS)
				.sheet(isPresented: .constant(showNameSheet)) {
					NameSheet()
						.presentationDetents([.medium])
						.presentationDragIndicator(.hidden)
						.interactiveDismissDisabled()
						.monospaced()
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
