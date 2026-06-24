//
//  ContentView.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
#if os(iOS)
import WatchConnectivity

enum SyncMode {
	case normal, loading, success, error
}
#endif // os(iOS)

struct ContentView: View {
#if os(iOS)
	@State private var watchSync = PhoneWatchSyncBridge()
	@State private var rootSyncStatus = SyncMode.normal
#endif // os(iOS)

	@Binding var expanded: WindowMode

	var body: some View {
#if os(iOS)
		ProminentActionTabView(
			watchSync: $watchSync,
			rootSyncStatus: $rootSyncStatus
		)
		.ignoresSafeArea()
#else
		TabView {
			Tab("Timetable", systemImage: "calendar") {
				TimetableView(expanded: $expanded)
			}

			Tab("Settings", systemImage: "gear") {
				SettingsView(expanded: $expanded)
			}
		}
#endif
	}
}

#if os(iOS)

func makeCustomShareImage() -> UIImage? {
	let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold, scale: .large)
	guard let symbolImage = UIImage(systemName: "square.and.arrow.up", withConfiguration: config) else { return nil }

	let canvasSize = CGSize(width: symbolImage.size.width, height: symbolImage.size.height + 6)

	let renderer = UIGraphicsImageRenderer(size: canvasSize)
	let staticImage = renderer.image { _ in
		let rect = CGRect(
			x: 0,
			y: 0,
			width: symbolImage.size.width,
			height: symbolImage.size.height
		)
		symbolImage.draw(in: rect)
	}

	// 4. Return as a raw template, stripping all "fill" metadata out permanently
	return staticImage.withRenderingMode(.alwaysTemplate)
}

struct ProminentActionTabView: UIViewControllerRepresentable {
	@Binding var watchSync: PhoneWatchSyncBridge
	@Binding var rootSyncStatus: SyncMode

	let prominentTabIdentifier = "prominent-share-action"

	func makeCoordinator() -> Coordinator {
		Coordinator(prominentTabIdentifier: prominentTabIdentifier)
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
			}
		]

		tabBarController.selectedTab = tabBarController.tabs.first
		tabBarController.prominentTabIdentifier = prominentTabIdentifier

		return tabBarController
	}

	func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
		context.coordinator.prominentTabIdentifier = prominentTabIdentifier
	}

	final class Coordinator: NSObject, UITabBarControllerDelegate {
		var prominentTabIdentifier: String


		init(prominentTabIdentifier: String) {
			self.prominentTabIdentifier = prominentTabIdentifier

		}

		func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
			guard tab.identifier == prominentTabIdentifier else {
				return true
			}

			// Intercept the tab press and kick off the asynchronous workflow
			presentSharePassWorkflow(from: tabBarController)
			return false
		}

		private func presentSharePassWorkflow(from tabBarController: UITabBarController) {
			guard tabBarController.presentedViewController == nil else { return }


			let loadingVC = UIViewController()
			loadingVC.modalPresentationStyle = .overFullScreen
			loadingVC.modalTransitionStyle = .crossDissolve

			let blurEffect = UIBlurEffect(style: .systemMaterial)
			let blurView = UIVisualEffectView(effect: blurEffect)
			blurView.frame = loadingVC.view.bounds
			blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			loadingVC.view.addSubview(blurView)

			let spinner = UIActivityIndicatorView(style: .large)
			spinner.center = loadingVC.view.center
			spinner.startAnimating()
			loadingVC.view.addSubview(spinner)

			tabBarController.present(loadingVC, animated: true) {

				Task.detached(priority: .userInitiated) { [self] in
					do {

						let url = try generatePass()


						await MainActor.run {
							loadingVC.dismiss(animated: true) {
								self.presentShareSheet(with: url, from: tabBarController)
							}
						}
					} catch {
						print("[Wallet] Background Share Error: \(error)")
						await MainActor.run {
							loadingVC.dismiss(animated: true) {
								self.presentErrorAlert(from: tabBarController)
							}
						}
					}
				}
			}
		}

		private func presentShareSheet(with fileURL: URL, from tabBarController: UITabBarController) {
			// Passing a local file URL pointing to a '.pkpass' enables standard file system operations natively
			let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

			// Prevent crashes on iPad layouts by explicitly pinning the anchor popover layout
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

		private func presentErrorAlert(from tabBarController: UITabBarController) {
			let alert = UIAlertController(title: "Error", message: "Unable to generate your shareable pass.", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			tabBarController.present(alert, animated: true)
		}
	}
}
#endif // os(iOS)

#Preview {
	ContentView(expanded: .constant(.none))
}
