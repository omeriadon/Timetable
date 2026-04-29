//
//  MessagesViewController.swift
//  PMS Timetable Message Extension
//
//  Created by Adon Omeri on 29/4/2026.
//

import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		print("[MessagesViewController] viewDidLoad called")
		setupSwiftUI()
	}

	override func willBecomeActive(with conversation: MSConversation) {
		super.willBecomeActive(with: conversation)
		print("[MessagesViewController] willBecomeActive called")

		if self.presentationStyle == .compact {
			self.requestPresentationStyle(.compact)
		}
	}

	private func setupSwiftUI() {
		print("[MessagesViewController] setupSwiftUI called")
		
		let timetableView = TimetableView()
		let hostingController = UIHostingController(rootView: timetableView)

		// Clear backgrounds
		hostingController.view.backgroundColor = .clear
		view.backgroundColor = .clear

		// Add as child view controller
		addChild(hostingController)
		view.addSubview(hostingController.view)

		// Set up constraints
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
			hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
		])

		// Complete the transition
		hostingController.didMove(toParent: self)
		
		print("[MessagesViewController] SwiftUI view setup complete")
	}

	override func didReceive(_ message: MSMessage, conversation: MSConversation) {
		super.didReceive(message, conversation: conversation)
		print("[MessagesViewController] didReceive called")
		
		if let fileURL = message.url, fileURL.pathExtension == "timetable" {
			let result = TimetableFileHandler.handleTimetableFile(at: fileURL)
			print("[Message Extension] Import result: \(result.message)")
		}
	}
}
