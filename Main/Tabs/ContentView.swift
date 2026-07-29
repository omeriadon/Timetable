//
//   ContentView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import Defaults
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
		case settings
		case friends
		case administration
	}

	struct ContentView: View {
		@State private var networkManager = NetworkManager.shared
		@Environment(\.statusBadgeManager) private var statusBadgeManager

		@State private var watchSync = PhoneWatchSyncBridge.shared
		@State private var rootSyncStatus = SyncMode.normal

		@Binding var expanded: WindowMode
		@State private var selectedTab: MainTab = .timetable

		var body: some View {
			ProminentActionTabView(
				selectedTab: $selectedTab,
				watchSync: $watchSync,
				rootSyncStatus: $rootSyncStatus
			)
			.ignoresSafeArea()
			.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
				selectedTab = .timetable
			}
			.onReceive(NotificationCenter.default.publisher(for: .administrationAuthorityInvalidated)) { _ in
				Task {
					_ = try? await SessionStore.shared.refreshProfile()
				}
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
}

#if os(iOS)

	// MARK: - Tab View Bridge

	struct ProminentActionTabView: UIViewControllerRepresentable {
		@Binding var selectedTab: MainTab
		@Binding var watchSync: PhoneWatchSyncBridge
		@Binding var rootSyncStatus: SyncMode
		@Default(.accountProfile) private var accountProfile

		func makeCoordinator() -> Coordinator {
			Coordinator(self)
		}

		func makeUIViewController(context: Context) -> UITabBarController {
			let tabBarController = UITabBarController()

			configureTabBarAppearance(tabBarController.tabBar)

			tabBarController.delegate = context.coordinator
			context.coordinator.tabBarController = tabBarController

			var tabs = [
				UITab(title: "Timetable", image: UIImage(systemName: "calendar.day.timeline.left"), identifier: "timetable") { _ in
					UIHostingController(rootView: TimetableView(watchSync: $watchSync, syncStatus: $rootSyncStatus))
				},
				UITab(title: "Friends", image: UIImage(systemName: "person.2"), identifier: "friends") { _ in
					UIHostingController(rootView: FriendsView())
				},
				UITab(title: "Settings", image: UIImage(systemName: "gear"), identifier: "settings") { _ in
					UIHostingController(rootView: SettingsView(watchSync: watchSync, syncStatus: $rootSyncStatus))
				},
			]
			if canShowAdministration {
				tabs.append(UITab(title: "Admin", image: UIImage(systemName: "calendar.badge.lock"), identifier: "administration") { _ in
					UIHostingController(rootView: AdministrationView())
				})
			}
			tabBarController.tabs = tabs

			tabBarController.selectedTab = tabBarController.tabs.first
			return tabBarController
		}

		func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {
			context.coordinator.parent = self
			let hasAdministrationTab = tabBarController.tabs.contains { $0.identifier == "administration" }
			if canShowAdministration != hasAdministrationTab {
				if canShowAdministration {
					tabBarController.tabs.append(UITab(title: "Admin", image: UIImage(systemName: "calendar.badge.lock"), identifier: "administration") { _ in
						UIHostingController(rootView: AdministrationView())
					})
				} else {
					tabBarController.tabs.removeAll { $0.identifier == "administration" }
					if selectedTab == .administration {
						selectedTab = .timetable
					}
				}
			}
			context.coordinator.selectTabIfRequested(selectedTab)
		}

		private var canShowAdministration: Bool {
			accountProfile?.authority.isAdministrator ?? false
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

		final class Coordinator: NSObject, UITabBarControllerDelegate {
			var parent: ProminentActionTabView
			weak var tabBarController: UITabBarController?
			private var requestedTab: MainTab?

			init(_ parent: ProminentActionTabView) {
				self.parent = parent
				super.init()
			}

			func tabBarController(
				_ tabBarController: UITabBarController,
				shouldSelectTab tab: UITab
			) -> Bool {
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

			func tabBarController(_ tabBarController: UITabBarController, didSelect _: UIViewController) {
				let selectedTab: MainTab = switch tabBarController.selectedTab?.identifier {
					case "settings": .settings
					case "friends": .friends
					case "administration": .administration
					default: .timetable
				}
				requestedTab = selectedTab
				parent.selectedTab = selectedTab
			}

			func selectTabIfRequested(_ tab: MainTab) {
				guard requestedTab != tab else {
					return
				}

				requestedTab = tab

				guard let tabBarController else { return }
				let identifier = switch tab {
					case .timetable: "timetable"
					case .settings: "settings"
					case .friends: "friends"
					case .administration: "administration"
				}
				guard let target = tabBarController.tabs.first(where: { $0.identifier == identifier }) else { return }
				if tabBarController.selectedTab?.identifier != target.identifier {
					tabBarController.selectedTab = target
				}
			}
		}
	}

	#Preview {
		ContentView(expanded: .constant(.none))
	}
#endif // os(iOS)
