import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
	private var hostingController: UIHostingController<MessagesRootView>?

	override func viewDidLoad() {
		super.viewDidLoad()

		let hostingController = UIHostingController(rootView: MessagesRootView())
		addChild(hostingController)
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(hostingController.view)
		NSLayoutConstraint.activate([
			hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
			hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
		])
		hostingController.didMove(toParent: self)
		self.hostingController = hostingController
	}
}
