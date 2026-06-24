//
//  ContentView.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import SwiftUI
#if os(iOS)
import VisualEffectBlurView
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

	// 1. Keep it as .alwaysTemplate here so the tint color applies correctly during rendering
	guard let symbolImage = UIImage(systemName: "paperplane", withConfiguration: config)?
		.withTintColor(.systemBlue, renderingMode: .alwaysTemplate)
	else {
		return nil
	}

	let canvasSize = CGSize(
		width: symbolImage.size.width + 2, // Slight adjustment to prevent clipping on the sides
		height: symbolImage.size.height + 6
	)

	let renderer = UIGraphicsImageRenderer(size: canvasSize)
	let renderedImage = renderer.image { _ in
		let rect = CGRect(
			x: 1,
			y: 4,
			width: symbolImage.size.width,
			height: symbolImage.size.height
		)

		symbolImage.draw(in: rect)
	}

	// 2. Crucial Step: Tell the UITabBar to use the original colors of the rendered image
	return renderedImage.withRenderingMode(.alwaysOriginal)
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

	/// 2. Conformed Coordinator to UIAdaptivePresentationControllerDelegate
	final class Coordinator: NSObject, UITabBarControllerDelegate, UIAdaptivePresentationControllerDelegate {
		var prominentTabIdentifier: String
		private var activeBlurView: VisualEffectBlurView? // Keep track of the blur view instance

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
			Task.detached(priority: .userInitiated) { [self] in
				do {
					let url = try await generatePass()

					await MainActor.run {
						self.presentShareSheet(with: url, from: tabBarController)
					}
				} catch {
					print("[Wallet] Background Share Error: \(error)")
					await MainActor.run {
						self.presentErrorAlert(from: tabBarController)
					}
				}
			}
		}

		private func presentShareSheet(with fileURL: URL, from tabBarController: UITabBarController) {
			// FIX: Added 'try?' to handle the throwing initializer safely
			guard let blurView = try? VisualEffectBlurView(blurEffectStyle: .regular) else {
				print("Error: VisualEffectBlurView failed to initialize.")
				return
			}

			blurView.blurRadius = 0
			blurView.frame = tabBarController.view.bounds
			blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			tabBarController.view.addSubview(blurView)
			activeBlurView = blurView

			// 1. Animate the blur radius up to 5px over 0.4 seconds
			UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
				blurView.blurRadius = 4
			}, completion: nil)

			let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

			// Assign the presentation delegate to catch interactive swipe-to-dismiss actions
			activityViewController.presentationController?.delegate = self

			// Fallback handler for button-based dismissals (like tapping an action or "Close")
			activityViewController.completionWithItemsHandler = { [weak self, weak tabBarController] _, _, _, _ in
				guard let self = self else { return }
				// Only run if the swipe gesture delegate didn't already clean it up
				if self.activeBlurView?.superview != nil {
					self.animateBlurOut(alongside: tabBarController?.transitionCoordinator)
				}
			}

			// Popover presentation configuration for iPad
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

		/// 7. This triggers the split second a user starts interactively swiping down the share sheet
		func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
			animateBlurOut(alongside: presentationController.presentedViewController.transitionCoordinator)
		}

		/// Helper method to handle the matching 0.4s ease-out animation
		private func animateBlurOut(alongside coordinator: UIViewControllerTransitionCoordinator?) {
			guard let blurView = activeBlurView else { return }

			if let coordinator = coordinator {
				coordinator.animate(alongsideTransition: { _ in
					blurView.blurRadius = 0
				}, completion: { _ in
					blurView.removeFromSuperview()
					self.activeBlurView = nil
				})
			} else {
				UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
					blurView.blurRadius = 0
				}, completion: { _ in
					blurView.removeFromSuperview()
					self.activeBlurView = nil
				})
			}
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
