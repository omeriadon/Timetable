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
#endif

struct ContentView: View {
#if os(iOS)
	@State private var watchSync = PhoneWatchSyncBridge()
	@State private var rootSyncStatus = SyncMode.normal
#endif

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

// MARK: - Custom Backdrop Blur

/// A custom visual effect view that extracts its Core Animation backdrop layer
/// to allow direct manipulation and animation of the blur radius value.
final class CustomBackdropBlurView: UIVisualEffectView {
	private var blurFilter: NSObject?

	init() {
		super.init(effect: UIBlurEffect(style: .regular))

		// Access the private CAFilter class
		guard let CAFilter = NSClassFromString("CAFilter")! as? NSObject.Type else {
			print("[CustomBlur] Error: Can't find CAFilter class")
			return
		}

		// Create a standard gaussian blur instead of a variable blur
		guard let filter = CAFilter.perform(NSSelectorFromString("filterWithType:"), with: "gaussianBlur")?.takeUnretainedValue() as? NSObject else {
			print("[CustomBlur] Error: Can't create gaussianBlur")
			return
		}

		self.blurFilter = filter

		// Name the filter so we can target it with CABasicAnimation keypaths
		filter.setValue("gaussianBlur", forKey: "name")
		filter.setValue(0.0, forKey: "inputRadius")
		filter.setValue(true, forKey: "inputNormalizeEdges")

		guard let backdropLayer = subviews.first?.layer else { return }
		backdropLayer.filters = [filter]

		// Hide the standard dimming/tint views to prevent hard lines or color overlays
		for subview in subviews.dropFirst() {
			subview.alpha = 0
		}
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/// Animates the blur radius directly on the Core Animation layer
	func animateRadius(to radius: CGFloat, duration: TimeInterval) {
		guard let backdropLayer = subviews.first?.layer, let filter = blurFilter else { return }

		let currentRadius = filter.value(forKey: "inputRadius") as? CGFloat ?? 0.0

		let animation = CABasicAnimation(keyPath: "filters.gaussianBlur.inputRadius")
		animation.fromValue = currentRadius
		animation.toValue = radius
		animation.duration = duration
		animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
		animation.fillMode = .forwards
		animation.isRemovedOnCompletion = false

		backdropLayer.add(animation, forKey: "radiusAnimation")

		// Update the underlying model value
		filter.setValue(radius, forKey: "inputRadius")
		backdropLayer.filters = [filter]
	}
}

// MARK: - Tab View Bridge

struct ProminentActionTabView: UIViewControllerRepresentable {
	@Binding var watchSync: PhoneWatchSyncBridge
	@Binding var rootSyncStatus: SyncMode

	private let prominentTabIdentifier = "prominent-share-action"

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
		var prominentTabIdentifier: String
		private var activeBlurView: CustomBackdropBlurView?

		init(prominentTabIdentifier: String) {
			self.prominentTabIdentifier = prominentTabIdentifier
		}

		func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
			guard tab.identifier == prominentTabIdentifier else {
				return true
			}

			guard activeBlurView == nil else {
				return false
			}

			presentBlur(in: tabBarController)
			presentSharePassWorkflow(from: tabBarController)

			return false
		}

		private func presentSharePassWorkflow(from tabBarController: UITabBarController) {
			Task { [weak self, weak tabBarController] in
				guard let self, let tabBarController else { return }

				do {
					let url = try await generatePass()
					await MainActor.run {
						self.presentShareSheet(with: url, from: tabBarController)
					}
				} catch {
					print("[Wallet] Background Share Error: \(error)")
					await MainActor.run {
						self.dismissBlur(animated: true) {
							self.presentErrorAlert(from: tabBarController)
						}
					}
				}
			}
		}

		private func presentBlur(in tabBarController: UITabBarController) {
			let blurView = CustomBackdropBlurView()
			blurView.frame = tabBarController.view.bounds
			blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

			tabBarController.view.addSubview(blurView)
			activeBlurView = blurView

			// Animate purely the radius taking 3.5 seconds
			blurView.animateRadius(to: 3, duration: 3.5)
		}

		private func presentShareSheet(with fileURL: URL, from tabBarController: UITabBarController) {
			let activityViewController = UIActivityViewController(
				activityItems: [fileURL],
				applicationActivities: nil
			)

			activityViewController.presentationController?.delegate = self
			activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
				self?.dismissBlur(animated: true)
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

		func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
			guard let coordinator = presentationController.presentedViewController.transitionCoordinator else {
				dismissBlur(animated: true)
				return
			}

			// Syncs the exact 2.5s custom animation requirement during swipe dismissal
			coordinator.animate(alongsideTransition: { [weak self] _ in
				self?.dismissBlur(animated: true)
			}, completion: nil)
		}

		private func dismissBlur(animated: Bool, completion: (() -> Void)? = nil) {
			guard let blurView = activeBlurView else {
				completion?()
				return
			}

			let cleanup = { [weak self] in
				blurView.removeFromSuperview()
				self?.activeBlurView = nil
				completion?()
			}

			if animated {
				// Use CATransaction to wrap the 2.5s animation and safely trigger the cleanup callback
				CATransaction.begin()
				CATransaction.setCompletionBlock {
					cleanup()
				}
				blurView.animateRadius(to: 0, duration: 2.5)
				CATransaction.commit()
			} else {
				cleanup()
			}
		}

		private func presentErrorAlert(from tabBarController: UITabBarController) {
			let alert = UIAlertController(
				title: "Error",
				message: "Unable to generate your shareable pass.",
				preferredStyle: .alert
			)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			tabBarController.present(alert, animated: true)
		}
	}
}
#endif

#Preview {
	ContentView(expanded: .constant(.none))
}
