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

		private var progressTimer: Timer?
		private var currentAngle: CGFloat = 0

		init(prominentTabIdentifier: String) {
			self.prominentTabIdentifier = prominentTabIdentifier
		}

		func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
			guard tab.identifier == prominentTabIdentifier else {
				return true
			}

			presentSharePassWorkflow(from: tabBarController, currentTab: tab)
			return false
		}

		private func presentSharePassWorkflow(from tabBarController: UITabBarController, currentTab: UITab) {
			// Avoid triggering multiple tasks if tapped repeatedly while loading
			guard progressTimer == nil else { return }

			// 1. Start spinning the progress symbol on the main thread
			startProgressAnimation(for: currentTab)

			// 2. Safely kick off generation on a background core
			Task.detached(priority: .userInitiated) { [self] in
				do {
					let url = try await generatePass()

					await MainActor.run {
						self.stopProgressAnimation(for: currentTab)
						self.presentShareSheet(with: url, from: tabBarController)
					}
				} catch {
					Print("[Wallet] Background Share Error: \(error)")
					await MainActor.run {
						self.stopProgressAnimation(for: currentTab)
						self.presentErrorAlert(from: tabBarController)
					}
				}
			}
		}

		// MARK: - Tab Bar Icon Spinner Logic

		private func startProgressAnimation(for tab: UITab) {
			currentAngle = 0

			progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
				guard let self = self else { return }
				self.currentAngle += 0.08

				let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold, scale: .large)
				guard let progressImage = UIImage(systemName: "paperplane", withConfiguration: config) else { return }

				let canvasSize = CGSize(width: progressImage.size.width, height: progressImage.size.height + 6)
				let renderer = UIGraphicsImageRenderer(size: canvasSize)

				let rotatedImage = renderer.image { context in
					context.cgContext.translateBy(x: canvasSize.width / 2, y: canvasSize.height / 2)
					context.cgContext.rotate(by: self.currentAngle)

					progressImage.draw(in: CGRect(
						x: -progressImage.size.width / 2,
						y: -progressImage.size.height / 2,
						width: progressImage.size.width,
						height: progressImage.size.height
					))
				}

				tab.image = rotatedImage.withRenderingMode(.alwaysTemplate)
			}
		}

		private func stopProgressAnimation(for tab: UITab) {
			progressTimer?.invalidate()
			progressTimer = nil

			// Revert seamlessly to your original clean share image layout
			tab.image = makeCustomShareImage()
		}

		// MARK: - Presentation Destinations

		private func presentShareSheet(with fileURL: URL, from tabBarController: UITabBarController) {
			let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

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
