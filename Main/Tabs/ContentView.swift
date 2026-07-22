//
//   ContentView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

#if os(iOS)
	import UIKit
	import WatchConnectivity
#endif

#if os(iOS)
	private enum TabBarFont {
		static let uiFont = UIFont.monospacedSystemFont(
			ofSize: 11,
			weight: .medium
		)
	}

	enum SyncMode {
		case normal, loading, success, error
	}

	enum MainTab: String, Hashable {
		case timetable
		case share
		case settings
		case search
	}

	struct ContentView: View {
		@State private var networkManager = NetworkManager.shared
		@Environment(\.statusBadgeManager) private var statusBadgeManager

		@State private var watchSync = PhoneWatchSyncBridge.shared
		@State private var rootSyncStatus = SyncMode.normal
		@State private var isBlurred = false
		@State private var showShareSelection = false
		@State private var isShareSheetUpcoming = false
		@State private var isAliasEditorUpcoming = false
		@State private var showAliasEditor = false
		@Environment(\.accessibilityReduceMotion) private var reduceMotion

		@Binding var expanded: WindowMode
		@State private var selectedTab: MainTab = .timetable

		var body: some View {
			ProminentActionTabView(
				selectedTab: $selectedTab,
				watchSync: $watchSync,
				rootSyncStatus: $rootSyncStatus,
				isBlurred: $isBlurred,
				showShareSelection: $showShareSelection
			)
			.animation(.smooth, value: isBlurred)
			.ignoresSafeArea()
			.sheet(isPresented: $showShareSelection, onDismiss: {
				if isAliasEditorUpcoming {
					showAliasEditor = true
					isAliasEditorUpcoming = false
				} else if !isShareSheetUpcoming {
					isBlurred = false
				}
				isShareSheetUpcoming = false
			}) {
				ShareSelectionSheet(onSelect: { selectedItem in
					isShareSheetUpcoming = true
					showShareSelection = false
					NotificationCenter.default.post(
						name: .shareTimetableItem,
						object: selectedItem
					)
				}, onCustomize: {
					isAliasEditorUpcoming = true
					showShareSelection = false
				})
				.presentationDetents([.fraction(0.5)])
				.presentationDragIndicator(.hidden)
				.interactiveDismissDisabled(false)
			}
			.sheet(isPresented: $showAliasEditor) {
				TimetableShareAliasSheet()
			}
			.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
				selectedTab = .timetable
			}
			.task {
				networkManager.startMonitoring()
			}
		}
	}

#endif // os(iOS)

extension Notification.Name {
	static let openSettingsTab = Notification.Name("openSettingsTab")
	static let openTimetableTab = Notification.Name("openTimetableTab")
	static let shareTimetableItem = Notification.Name("shareTimetableItem")
}

#if os(iOS)

	// MARK: - Tab View Bridge

	struct ProminentActionTabView: UIViewControllerRepresentable {
		@Binding var selectedTab: MainTab
		@Binding var watchSync: PhoneWatchSyncBridge
		@Binding var rootSyncStatus: SyncMode
		@Binding var isBlurred: Bool
		@Binding var showShareSelection: Bool

		let prominentTabIdentifier = "prominent-share-action"

		func makeCoordinator() -> Coordinator {
			Coordinator(self)
		}

		func makeUIViewController(context: Context) -> UITabBarController {
			let tabBarController = UITabBarController()

			configureTabBarAppearance(tabBarController.tabBar)

			tabBarController.delegate = context.coordinator
			context.coordinator.tabBarController = tabBarController

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
			if #available(iOS 27.0, *) {
				tabBarController.prominentTabIdentifier = prominentTabIdentifier
			}

			return tabBarController
		}

		func updateUIViewController(_: UITabBarController, context: Context) {
			context.coordinator.parent = self
			context.coordinator.selectTab(selectedTab)
		}

		@MainActor
		private func configureTabBarAppearance(_ tabBar: UITabBar) {
			let appearance = UITabBarAppearance()
			appearance.configureWithDefaultBackground()

			let attributes: [NSAttributedString.Key: Any] = [
				.font: TabBarFont.uiFont,
			]

			let layouts = [
				appearance.stackedLayoutAppearance,
				appearance.inlineLayoutAppearance,
				appearance.compactInlineLayoutAppearance,
			]

			for layout in layouts {
				layout.normal.titleTextAttributes = attributes
				layout.selected.titleTextAttributes = attributes
				layout.disabled.titleTextAttributes = attributes
				layout.focused.titleTextAttributes = attributes
			}

			tabBar.standardAppearance = appearance
			tabBar.scrollEdgeAppearance = appearance
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
			weak var tabBarController: UITabBarController?

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

			func tabBarController(
				_ tabBarController: UITabBarController,
				shouldSelectTab tab: UITab
			) -> Bool {
				guard tab.identifier == parent.prominentTabIdentifier else {
					if tab.identifier != tabBarController.selectedTab?.identifier {
						UIView.transition(
							with: tabBarController.view,
							duration: 0.1,
							options: [.transitionCrossDissolve, .allowAnimatedContent],
							animations: {}
						)
					}

					return true
				}

				guard !parent.isBlurred else {
					return false
				}

				let currentTab = tabBarController.selectedTab

				parent.isBlurred = true
				parent.showShareSelection = true

				DispatchQueue.main.async {
					tabBarController.selectedTab = currentTab
				}

				return false
			}

			func tabBarController(_ tabBarController: UITabBarController, didSelect _: UIViewController) {
				parent.selectedTab = switch tabBarController.selectedTab?.identifier {
					case "settings": .settings
					case "search": .search
					default: .timetable
				}
			}

			func selectTab(_ tab: MainTab) {
				guard let tabBarController else { return }
				let identifier = switch tab {
					case .timetable: "timetable"
					case .share: parent.prominentTabIdentifier
					case .settings: "settings"
					case .search: "search"
				}
				guard let target = tabBarController.tabs.first(where: { $0.identifier == identifier }) else { return }
				if tabBarController.selectedTab?.identifier != target.identifier {
					tabBarController.selectedTab = target
				}
			}

			@objc private func handleShareTimetableNotification(_ notification: Notification) {
				guard let selectedItem = notification.object as? SelectedShareItem else {
					parent.isBlurred = false
					return
				}

				Task { @MainActor [weak self] in
					guard let self else { return }

					try? await Task.sleep(for: .milliseconds(350))

					if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
					   let window = windowScene.windows.first,
					   let rootVC = window.rootViewController
					{
						var topController = rootVC
						while let presented = topController.presentedViewController, !presented.isBeingDismissed {
							topController = presented
						}

						presentShareWorkflow(for: selectedItem, from: topController)
					} else {
						parent.isBlurred = false
					}
				}
			}

			private func presentShareWorkflow(for selectedItem: SelectedShareItem, from targetVC: UIViewController) {
				Task { @MainActor [weak self, weak targetVC] in
					guard let self, let targetVC else { return }
					guard SessionStore.shared.isAuthenticated else {
						parent.isBlurred = false
						StatusBadgeManager.shared.signInRequired()
						return
					}

					do {
						let url: URL? = switch selectedItem {
							case let .owner(id): TimetableShareURL.ownerURL(id: id)
							case let .authored(id, _): TimetableShareURL.url(locator: id.uuidString)
							case let .received(id, _): TimetableShareURL.url(locator: id)
						}
						guard let url else {
							throw URLError(.badURL)
						}
						presentShareSheet(with: url, from: targetVC)
					} catch where error.isCancellation {
						parent.isBlurred = false
						return
					} catch {
						PrintError("Background share error: \(error)")
						parent.isBlurred = false
						StatusBadgeManager.shared.addBadge(
							id: UUID(),
							title: "Unable to share timetable.",
							priority: 4,
							view: .error
						)
					}
				}
			}

			private func presentShareSheet(with url: URL, from targetVC: UIViewController) {
				let activityViewController = UIActivityViewController(
					activityItems: [url],
					applicationActivities: nil
				)

				activityViewController.presentationController?.delegate = self

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

	#Preview {
		ContentView(expanded: .constant(.none))
	}
#endif // os(iOS)
