
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
	let fontDesign: AppFontDesign

	func makeCoordinator() -> Coordinator {
		Coordinator(selection: $selection)
	}

	func makeUIViewController(context: Context) -> UITabBarController {
		let controller = UITabBarController()
		controller.delegate = context.coordinator
		controller.tabBarMinimizeBehavior = .onScrollDown
		let controllers = items.map(makeViewController)
		context.coordinator.updateControllers(controllers, for: items)
		controller.viewControllers = controllers
		applyFontDesign(to: controller)
		selectValidTab(in: controller, coordinator: context.coordinator)
		return controller
	}

	func updateUIViewController(_ controller: UITabBarController, context: Context) {
		let controllers = items.map { item in
			context.coordinator.controller(for: item.value) ?? makeViewController(item: item)
		}

		for (item, hostingController) in zip(items, controllers) {
			updateTabBarItem(of: hostingController, with: item)
		}

		context.coordinator.updateControllers(controllers, for: items)
		if !hasSameControllers(controller.viewControllers, controllers) {
			controller.setViewControllers(controllers, animated: false)
		}
		applyFontDesign(to: controller)
		selectValidTab(in: controller, coordinator: context.coordinator)
	}

	private func applyFontDesign(to controller: UITabBarController) {
		let design: UIFontDescriptor.SystemDesign = switch fontDesign {
			case .monospaced:
				.monospaced
			case .rounded:
				.rounded
			case .expanded:
				.default
		}
		let baseFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
		let font = baseFont.fontDescriptor.withDesign(design)
			.map { UIFont(descriptor: $0, size: 10) }
			?? baseFont
		for item in controller.tabBar.items ?? [] {
			item.setTitleTextAttributes([.font: font], for: .normal)
			item.setTitleTextAttributes([.font: font], for: .selected)
		}
	}

	private func makeViewController(item: UIKitTabItem) -> UIViewController {
		let controller = UIHostingController(rootView: item.content)
		controller.tabBarItem = UITabBarItem()
		updateTabBarItem(of: controller, with: item)
		return controller
	}

	private func updateTabBarItem(of controller: UIViewController, with item: UIKitTabItem) {
		controller.tabBarItem.title = item.title
		controller.tabBarItem.image = UIImage(systemName: item.systemImage)
		controller.tabBarItem.badgeValue = item.badge
	}

	private func hasSameControllers(
		_ current: [UIViewController]?,
		_ desired: [UIViewController]
	) -> Bool {
		guard let current, current.count == desired.count else {
			return false
		}
		return zip(current, desired).allSatisfy { $0 === $1 }
	}

	private func selectValidTab(
		in controller: UITabBarController,
		coordinator: Coordinator
	) {
		let validSelection = items.contains(where: { $0.value == selection })
			? selection
			: items.first?.value
		guard let validSelection,
		      let selectedController = coordinator.controller(for: validSelection),
		      let index = controller.viewControllers?.firstIndex(where: { $0 === selectedController })
		else {
			return
		}
		if controller.selectedIndex != index {
			controller.selectedIndex = index
		}
		coordinator.normalizeSelection(to: validSelection)
	}

	final class Coordinator: NSObject, UITabBarControllerDelegate {
		private let selection: Binding<MainTab>
		private var controllersByValue: [MainTab: UIViewController] = [:]

		init(selection: Binding<MainTab>) {
			self.selection = selection
		}

		func controller(for value: MainTab) -> UIViewController? {
			controllersByValue[value]
		}

		func updateControllers(_ controllers: [UIViewController], for items: [UIKitTabItem]) {
			var updatedControllers: [MainTab: UIViewController] = [:]
			for (item, controller) in zip(items, controllers) where updatedControllers[item.value] == nil {
				updatedControllers[item.value] = controller
			}
			controllersByValue = updatedControllers
		}

		func normalizeSelection(to value: MainTab) {
			guard selection.wrappedValue != value else {
				return
			}
			Task { @MainActor [weak self] in
				guard let self,
				      controllersByValue[value] != nil,
				      selection.wrappedValue != value
				else {
					return
				}
				selection.wrappedValue = value
			}
		}

		func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
			guard let value = controllersByValue.first(where: { $0.value === viewController })?.key else {
				return
			}

			Task { @MainActor [weak self, weak tabBarController, weak viewController] in
				guard let self,
				      let tabBarController,
				      let viewController,
				      tabBarController.selectedViewController === viewController,
				      controllersByValue[value] === viewController,
				      selection.wrappedValue != value
				else {
					return
				}
				selection.wrappedValue = value
			}
		}
	}
}

extension Array {
	func appendingIf(_ condition: Bool, _ item: @autoclosure () -> Element) -> [Element] {
		condition ? self + [item()] : self
	}
}
