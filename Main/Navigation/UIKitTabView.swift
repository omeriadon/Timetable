#if os(iOS)
	import SwiftUI
	import UIKit

	struct UIKitTabItem {
		let title: String
		let systemImage: String
		let value: MainTab
		let badge: String?
		let content: AnyView
	}

	struct UIKitTabView: UIViewControllerRepresentable {
		@Binding var selection: MainTab
		let items: [UIKitTabItem]

		func makeCoordinator() -> Coordinator {
			Coordinator(selection: $selection, items: items)
		}

		func makeUIViewController(context: Context) -> UITabBarController {
			let controller = UITabBarController()
			controller.delegate = context.coordinator
			controller.viewControllers = items.map(makeViewController)
			select(selection, in: controller)
			return controller
		}

		func updateUIViewController(_ controller: UITabBarController, context _: Context) {
			if controller.viewControllers?.count != items.count {
				controller.viewControllers = items.map(makeViewController)
			}

			for (index, item) in items.enumerated() {
				guard let hostingController = controller.viewControllers?[index] as? UIHostingController<AnyView> else {
					continue
				}
				hostingController.rootView = item.content
				hostingController.tabBarItem.badgeValue = item.badge
			}
			select(selection, in: controller)
		}

		private func makeViewController(item: UIKitTabItem) -> UIViewController {
			let controller = UIHostingController(rootView: item.content)
			controller.tabBarItem = UITabBarItem(
				title: item.title,
				image: UIImage(systemName: item.systemImage),
				tag: item.value.hashValue
			)
			controller.tabBarItem.badgeValue = item.badge
			return controller
		}

		private func select(_ value: MainTab, in controller: UITabBarController) {
			guard let index = items.firstIndex(where: { $0.value == value }) else { return }
			if controller.selectedIndex != index {
				controller.selectedIndex = index
			}
		}

		final class Coordinator: NSObject, UITabBarControllerDelegate {
			private let selection: Binding<MainTab>
			private let items: [UIKitTabItem]

			init(selection: Binding<MainTab>, items: [UIKitTabItem]) {
				self.selection = selection
				self.items = items
			}

			func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
				guard let index = tabBarController.viewControllers?.firstIndex(of: viewController),
				      items.indices.contains(index)
				else { return }
				selection.wrappedValue = items[index].value
			}

			func tabBarController(
				_: UITabBarController,
				animationControllerForTransitionFrom fromVC: UIViewController,
				to toVC: UIViewController
			) -> UIViewControllerAnimatedTransitioning? {
				TabTransitionAnimator(
					forward: toVC.view.frame.minX >= fromVC.view.frame.minX
				)
			}
		}
	}

	private extension Array {
		func appendingIf(_ condition: Bool, _ item: @autoclosure () -> Element) -> [Element] {
			condition ? self + [item()] : self
		}
	}

	private final class TabTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
		let forward: Bool

		init(forward: Bool) {
			self.forward = forward
		}

		func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
			0.28
		}

		func animateTransition(using context: UIViewControllerContextTransitioning) {
			guard let fromView = context.view(forKey: .from),
			      let toView = context.view(forKey: .to),
			      let container = context.containerView
			else {
				context.completeTransition(false)
				return
			}

			let offset = container.bounds.width * (forward ? 1 : -1)
			toView.frame = container.bounds.offsetBy(dx: offset, dy: 0)
			container.addSubview(toView)
			UIView.animate(
				withDuration: transitionDuration(using: context),
				options: [.curveEaseInOut]
			) {
				fromView.frame = container.bounds.offsetBy(dx: -offset, dy: 0)
				toView.frame = container.bounds
			} completion: { finished in
				context.completeTransition(finished)
			}
		}
	}
#endif
