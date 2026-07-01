//
//   ContentView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI
#if os(iOS)
	import WatchConnectivity

	enum SyncMode {
		case normal, loading, success, error
	}
#endif

struct ContentView: View {
	@State private var networkManager = NetworkManager.shared
	@Environment(\.statusBadgeManager) private var statusBadgeManager

	private let networkErrorBadgeID = UUID(uuidString: "7D38B39C-D45D-4DDD-9D6D-E3F886CC853B")!
	private let offlineBadgeID = UUID(uuidString: "5D75876A-CA6E-43BD-AC3E-0884A807BECD")!

	#if os(iOS)
		@State private var watchSync = PhoneWatchSyncBridge()
		@State private var rootSyncStatus = SyncMode.normal
		@State private var isBlurred = false
		@State private var isBlurMounted = false
		@State private var topBlurRadius: CGFloat = 0
		@State private var bottomBlurRadius: CGFloat = 0
		@Environment(\.accessibilityReduceMotion) private var reduceMotion
	#endif

	@Binding var expanded: WindowMode
	#if !os(iOS)
		@State private var selectedCompanionTab = "timetable"
	#endif

	var body: some View {
		Group {
			#if os(iOS)
				ProminentActionTabView(
					watchSync: $watchSync,
					rootSyncStatus: $rootSyncStatus,
					isBlurred: $isBlurred
				)
				.overlay {
					if isBlurMounted {
						VariableBlurView(
							topRadius: topBlurRadius,
							bottomRadius: bottomBlurRadius
						)
						.ignoresSafeArea()
						.allowsHitTesting(false)
					}
				}
				.ignoresSafeArea()
				.onChange(of: isBlurred, updateBlur)
			#else
				TabView(selection: $selectedCompanionTab) {
					Tab("Timetable", systemImage: "calendar", value: "timetable") {
						TimetableView(expanded: $expanded)
					}

					Tab("Settings", systemImage: "gear", value: "settings") {
						SettingsView(expanded: $expanded)
					}
				}
				.onReceive(NotificationCenter.default.publisher(for: .openSettingsTab)) { _ in selectedCompanionTab = "settings" }
			#endif
		}
		.onChange(of: networkManager.presentedAlert?.id) {
			guard let alert = networkManager.presentedAlert else { return }
			statusBadgeManager.addBadge(
				id: networkErrorBadgeID,
				title: alert.title,
				secondaryText: alert.message,
				priority: 5,
				view: .error
			)
			networkManager.presentedAlert = nil
		}
		.onChange(of: networkManager.offlineRequestAttempted) {
			guard networkManager.offlineRequestAttempted else { return }
			statusBadgeManager.addBadge(
				id: offlineBadgeID,
				title: "No Internet Connection",
				secondaryText: "Please check your network settings.",
				priority: 5,
				view: .error
			)
			networkManager.dismissOfflineBanner()
		}
		.task {
			networkManager.startMonitoring()
		}
	}

	#if os(iOS)
		private func updateBlur() {
			if isBlurred {
				isBlurMounted = true
				topBlurRadius = 0
				bottomBlurRadius = 0

				Task { @MainActor in
					await Task.yield()
					guard isBlurred else { return }
					withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.7)) {
						topBlurRadius = 0
						bottomBlurRadius = 8
					}
				}
			} else {
				withAnimation(
					reduceMotion ? nil : .easeOut(duration: 0.25),
					completionCriteria: .logicallyComplete
				) {
					topBlurRadius = 0
					bottomBlurRadius = 0
				} completion: {
					guard !isBlurred else { return }
					isBlurMounted = false
				}
			}
		}
	#endif
}

extension Notification.Name {
	static let openSettingsTab = Notification.Name("openSettingsTab")
}

#if os(iOS)

	// MARK: - Tab View Bridge

	struct ProminentActionTabView: UIViewControllerRepresentable {
		@Binding var watchSync: PhoneWatchSyncBridge
		@Binding var rootSyncStatus: SyncMode
		@Binding var isBlurred: Bool // 4. Receive Binding

		let prominentTabIdentifier = "prominent-share-action"

		func makeCoordinator() -> Coordinator {
			Coordinator(self)
		}

		func makeUIViewController(context: Context) -> UITabBarController {
			let tabBarController = UITabBarController()
			tabBarController.delegate = context.coordinator

			tabBarController.tabs = [
				UITab(title: "Timetable", image: UIImage(systemName: "calendar"), identifier: "timetable") { _ in
					UIHostingController(rootView: TimetableView(watchSync: $watchSync, syncStatus: $rootSyncStatus))
				},
				UITab(title: "Share", image: makeCustomShareImage(), identifier: prominentTabIdentifier) { _ in
					UIHostingController(rootView: EmptyView())
				},
				UITab(title: "Settings", image: UIImage(systemName: "gear"), identifier: "settings") { _ in
					UIHostingController(rootView: SettingsView(watchSync: watchSync, syncStatus: $rootSyncStatus))
				},
				UITab(title: "Search", image: UIImage(systemName: "magnifyingglass"), identifier: "search") { _ in
					UIHostingController(rootView: TimetableSearchView())
				},
			]

			tabBarController.selectedTab = tabBarController.tabs.first
			tabBarController.prominentTabIdentifier = prominentTabIdentifier

			return tabBarController
		}

		func updateUIViewController(_: UITabBarController, context: Context) {
			// Update coordinator parent if needed
			context.coordinator.parent = self
		}

		private func makeCustomShareImage() -> UIImage? {
			let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold, scale: .large)
			guard let symbolImage = UIImage(systemName: "paperplane", withConfiguration: config)?
				.withTintColor(.systemBlue, renderingMode: .alwaysTemplate)
			else {
				return nil
			}

			let canvasSize = CGSize(width: symbolImage.size.width + 2, height: symbolImage.size.height + 6)
			let renderer = UIGraphicsImageRenderer(size: canvasSize)

			let renderedImage = renderer.image { _ in
				symbolImage.draw(in: CGRect(x: 1, y: 4, width: symbolImage.size.width, height: symbolImage.size.height))
			}

			return renderedImage.withRenderingMode(.alwaysOriginal)
		}

		final class Coordinator: NSObject, UITabBarControllerDelegate, UIAdaptivePresentationControllerDelegate {
			var parent: ProminentActionTabView

			init(_ parent: ProminentActionTabView) {
				self.parent = parent
			}

			func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
				guard tab.identifier == parent.prominentTabIdentifier else {
					return true
				}

				guard !parent.isBlurred else {
					return false
				}

				parent.isBlurred = true
				presentSharePassWorkflow(from: tabBarController)

				return false
			}

			private func presentSharePassWorkflow(from tabBarController: UITabBarController) {
				Task { @MainActor [weak self, weak tabBarController] in
					guard let self, let tabBarController else { return }
					guard SessionStore.shared.isAuthenticated else {
						parent.isBlurred = false
						StatusBadgeManager.shared.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to share your timetable pass.", priority: 3, view: .warning)
						return
					}

					do {
						let url = try await WalletPassService.shared.ownerPassFileURL()
						presentShareSheet(with: url, from: tabBarController)
					} catch {
						PrintError("[Wallet] Background Share Error: \(error)")
						parent.isBlurred = false
						StatusBadgeManager.shared.addBadge(id: UUID(), title: "Unable to generate your shareable pass.", priority: 4, view: .error)
					}
				}
			}

			private func presentShareSheet(with fileURL: URL, from tabBarController: UITabBarController) {
				let activityViewController = UIActivityViewController(
					activityItems: [fileURL],
					applicationActivities: nil
				)

				activityViewController.presentationController?.delegate = self

				// 6. Un-blur when sheet is dismissed fully
				activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
					self?.parent.isBlurred = false
				}

				if let popoverController = activityViewController.popoverPresentationController {
					popoverController.sourceView = tabBarController.tabBar
					let tabBarWidth = tabBarController.tabBar.frame.width

					popoverController.sourceRect = CGRect(
						x: tabBarWidth / 2 - 25,
						y: 0,
						width: 50,
						height: tabBarController.tabBar.frame.height
					)
				}

				tabBarController.present(activityViewController, animated: true)
			}

			func presentationControllerWillDismiss(_: UIPresentationController) {
				parent.isBlurred = false
			}
		}
	}
#endif // os(iOS)

#Preview {
	ContentView(expanded: .constant(.none))
}
