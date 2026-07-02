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
		@State private var showShareSelection = false
		@State private var isShareSheetUpcoming = false
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
					isBlurred: $isBlurred,
					showShareSelection: $showShareSelection
				)
				.overlay {
					if isBlurMounted {
						VariableBlurView(
							topRadius: topBlurRadius,
							bottomRadius: bottomBlurRadius,
							animationDuration: reduceMotion ? 0 : (isBlurred ? 0.9 : 0.25)
						)
						.ignoresSafeArea()
						.allowsHitTesting(false)
					}
				}
				.ignoresSafeArea()
				.onChange(of: isBlurred, updateBlur)
				.sheet(isPresented: $showShareSelection) {
					if !isShareSheetUpcoming {
						Task { @MainActor in
							isBlurred = false
						}
					}
					isShareSheetUpcoming = false
				} content: {
					ShareSelectionSheet(onSelect: { selectedItem in
						isShareSheetUpcoming = true
						showShareSelection = false
						NotificationCenter.default.post(
							name: .shareTimetableItem,
							object: selectedItem
						)
					})
					.presentationDetents([.fraction(0.5)])
					.presentationDragIndicator(.hidden)
					.interactiveDismissDisabled(false)
				}
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
					topBlurRadius = 0
					bottomBlurRadius = 8
				}
			} else {
				topBlurRadius = 0
				bottomBlurRadius = 0

				Task { @MainActor in
					if !reduceMotion {
						try? await Task.sleep(for: .milliseconds(250))
					}
					guard !isBlurred else { return }
					isBlurMounted = false
				}
			}
		}
	#endif
}

extension Notification.Name {
	static let openSettingsTab = Notification.Name("openSettingsTab")
	static let shareTimetableItem = Notification.Name("shareTimetableItem")
}

#if os(iOS)

	// MARK: - Tab View Bridge

	struct ProminentActionTabView: UIViewControllerRepresentable {
		@Binding var watchSync: PhoneWatchSyncBridge
		@Binding var rootSyncStatus: SyncMode
		@Binding var isBlurred: Bool // 4. Receive Binding
		@Binding var showShareSelection: Bool

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
				super.init()
				NotificationCenter.default.addObserver(
					self,
					selector: #selector(handleShareTimetableNotification(_:)),
					name: .shareTimetableItem,
					object: nil
				)
			}

			deinit {
				NotificationCenter.default.removeObserver(self)
			}

			func tabBarController(_: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
				guard tab.identifier == parent.prominentTabIdentifier else {
					return true
				}

				guard !parent.isBlurred else {
					return false
				}

				parent.isBlurred = true
				parent.showShareSelection = true

				return false
			}

			@objc private func handleShareTimetableNotification(_ notification: Notification) {
				guard let selectedItem = notification.object as? SelectedShareItem else {
					parent.isBlurred = false
					return
				}

				Task { @MainActor [weak self] in
					guard let self else { return }

					// Wait for the SwiftUI sheet dismissal animation to complete
					try? await Task.sleep(for: .milliseconds(350))

					if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
					   let window = windowScene.windows.first,
					   let rootVC = window.rootViewController
					{
						var topController = rootVC
						while let presented = topController.presentedViewController, !presented.isBeingDismissed {
							topController = presented
						}

						presentSharePassWorkflow(for: selectedItem, from: topController)
					} else {
						parent.isBlurred = false
					}
				}
			}

			private func presentSharePassWorkflow(for selectedItem: SelectedShareItem, from targetVC: UIViewController) {
				Task { @MainActor [weak self, weak targetVC] in
					guard let self, let targetVC else { return }
					guard SessionStore.shared.isAuthenticated else {
						parent.isBlurred = false
						StatusBadgeManager.shared.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to use this feature.", priority: 3, view: .warning)
						return
					}

					do {
						let url: URL = switch selectedItem {
							case .owner:
								try await WalletPassService.shared.ownerPassFileURL()
							case let .authored(id, name):
								try await WalletPassService.shared.passFileURL(timetableID: id, name: name)
							case let .received(id, _):
								try await WalletPassService.shared.receivedPassFileURL(serialNumber: id)
						}
						presentShareSheet(with: url, from: targetVC)
					} catch where error.isCancellation {
						parent.isBlurred = false
						return
					} catch {
						PrintError("[Wallet] Background Share Error: \(error)")
						parent.isBlurred = false
						StatusBadgeManager.shared.addBadge(
							id: UUID(),
							title: "Unable to generate your shareable pass.",
							priority: 4,
							view: .error
						)
					}
				}
			}

			private func presentShareSheet(with fileURL: URL, from targetVC: UIViewController) {
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
					popoverController.sourceView = targetVC.view
					popoverController.sourceRect = CGRect(
						x: targetVC.view.bounds.midX,
						y: targetVC.view.bounds.midY,
						width: 0,
						height: 0
					)
					popoverController.permittedArrowDirections = []
				}

				targetVC.present(activityViewController, animated: true)
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
