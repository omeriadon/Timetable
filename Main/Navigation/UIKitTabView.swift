
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
		Coordinator(selection: $selection, items: items)
	}

	func makeUIViewController(context: Context) -> UITabBarController {
		let controller = UITabBarController()
		controller.delegate = context.coordinator
		controller.tabBarMinimizeBehavior = .onScrollDown
		controller.viewControllers = items.map(makeViewController)
		applyFontDesign(to: controller)
		select(selection, in: controller)
		return controller
	}

	func updateUIViewController(_ controller: UITabBarController, context: Context) {
		context.coordinator.updateItems(items)

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
		applyFontDesign(to: controller)
		select(selection, in: controller)
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
		private var itemValues: [MainTab]

		init(selection: Binding<MainTab>, items: [UIKitTabItem]) {
			self.selection = selection
			itemValues = items.map(\.value)
		}

		func updateItems(_ items: [UIKitTabItem]) {
			itemValues = items.map(\.value)
		}

		func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
			guard let index = tabBarController.viewControllers?.firstIndex(of: viewController),
			      itemValues.indices.contains(index)
			else { return }
			selection.wrappedValue = itemValues[index]
		}
	}
}

extension Array {
	func appendingIf(_ condition: Bool, _ item: @autoclosure () -> Element) -> [Element] {
		condition ? self + [item()] : self
	}
}
