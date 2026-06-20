//
//  MessagesViewController.swift
//  Timetable Message Extension
//
//  Created by Adon Omeri on 29/4/2026.
//

import Defaults
import Messages
import SwiftUI
import UIKit

class MessagesViewController: MSMessagesAppViewController {
	private var hostingController: UIHostingController<AnyView>?
	private var selectedMessageURL: URL?
	private var selectionRefreshAttempts = 0
	private let maxSelectionRefreshAttempts = 8

	override func viewDidLoad() {
		super.viewDidLoad()
		setupSwiftUI()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		startSelectionRefreshLoop()
	}

	override func willBecomeActive(with conversation: MSConversation) {
		super.willBecomeActive(with: conversation)
		if let url = conversation.selectedMessage?.url {
			selectedMessageURL = url
		}
		setupSwiftUI()
		startSelectionRefreshLoop()
	}

	override func didBecomeActive(with conversation: MSConversation) {
		super.didBecomeActive(with: conversation)
		selectedMessageURL = selectedMessageURL ?? conversation.selectedMessage?.url ?? extractURLFromExtensionContext()
		setupSwiftUI()
		startSelectionRefreshLoop()
	}

	override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
		super.didTransition(to: presentationStyle)
		setupSwiftUI()
	}

	override func didSelect(_ message: MSMessage, conversation: MSConversation) {
		super.didSelect(message, conversation: conversation)
		selectedMessageURL = message.url
		print("[MessagesExt] didSelect url: \(message.url?.absoluteString ?? "nil")")
		setupSwiftUI()
	}

	override func willSelect(_ message: MSMessage, conversation: MSConversation) {
		super.willSelect(message, conversation: conversation)
		print("[MessagesExt] willSelect url: \(message.url?.absoluteString ?? "nil")")
	}

	override func didReceive(_ message: MSMessage, conversation: MSConversation) {
		super.didReceive(message, conversation: conversation)
		if let url = message.url {
			selectedMessageURL = url
		}
	}

	override func contentSizeThatFits(_ size: CGSize) -> CGSize {
		if presentationStyle == .compact {
			return CGSize(width: size.width, height: 400)
		} else if presentationStyle == .expanded {
			return CGSize(width: size.width, height: 600)
		}
		return size
	}

	private func setupSwiftUI() {
		hostingController?.removeFromParent()
		hostingController?.view.removeFromSuperview()

		let userDisplayName = Defaults[.userDisplayName]
		let selectedMessage = activeConversation?.selectedMessage
		let messageURL = selectedMessageURL
			?? selectedMessage?.url
			?? extractURLFromExtensionContext()
		if selectedMessageURL == nil, let messageURL {
			selectedMessageURL = messageURL
		}
		let fallbackPayload = selectedMessage.flatMap(extractTimetablePayload)
		let hasSelectedMessage = selectedMessage != nil
		let view: any View = if hasSelectedMessage || messageURL != nil || fallbackPayload != nil {
			AnyView(
				ReceivedTimetableTranscriptView(messageUrl: messageURL, fallbackPayload: fallbackPayload) { [weak self] in
					guard let self else { return }
					if let messageURL {
						openContainingApp(with: messageURL)
					} else if let fallbackPayload, let url = makeDeepLinkFromEncodedPayload(fallbackPayload) {
						openContainingApp(with: url)
					}
				}
			)
		} else if presentationStyle == .transcript {
			AnyView(TranscriptPlaceholder())
		} else {
			AnyView(
				TimetableView { [weak self] _, subjects, completion in
					guard let self else {
						completion(.failure(MessageSendError.controllerDeallocated))
						return
					}
					sendTimetableMessage(senderName: userDisplayName, subjects: subjects, completion: completion)
				}
			)
		}

		let newController = UIHostingController(rootView: AnyView(view))
		newController.view.backgroundColor = .clear
		self.view.backgroundColor = .clear

		addChild(newController)
		self.view.addSubview(newController.view)

		newController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			newController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
			newController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			newController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			newController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
		])

		newController.didMove(toParent: self)
		hostingController = newController
	}

	private func startSelectionRefreshLoop() {
		selectionRefreshAttempts = 0
		refreshSelectionIfNeeded()
	}

	private func refreshSelectionIfNeeded() {
		let currentURL = selectedMessageURL
			?? activeConversation?.selectedMessage?.url
			?? extractURLFromExtensionContext()

		if currentURL != nil {
			if selectedMessageURL == nil {
				selectedMessageURL = currentURL
				setupSwiftUI()
			}
			return
		}

		guard selectionRefreshAttempts < maxSelectionRefreshAttempts else { return }
		selectionRefreshAttempts += 1
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
			self?.refreshSelectionIfNeeded()
		}
	}

	private func extractURLFromExtensionContext() -> URL? {
		guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
			return nil
		}

		for item in extensionItems {
			if let explicitURL = item.userInfo?["url"] as? URL {
				return explicitURL
			}
			if let urlString = item.userInfo?["url"] as? String, let parsed = URL(string: urlString) {
				return parsed
			}
			for provider in item.attachments ?? [] {
				if provider.hasItemConformingToTypeIdentifier("public.url") {
					var extractedURL: URL?
					let semaphore = DispatchSemaphore(value: 0)
					provider.loadItem(forTypeIdentifier: "public.url") { item, _ in
						if let url = item as? URL {
							extractedURL = url
						} else if let string = item as? String {
							extractedURL = URL(string: string)
						}
						semaphore.signal()
					}
					_ = semaphore.wait(timeout: .now() + 0.25)
					if let extractedURL {
						return extractedURL
					}
				}
			}
		}
		return nil
	}

	private func isTimetableDeepLink(_ url: URL) -> Bool {
		guard url.scheme == "timetable" else { return false }
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		return components?.queryItems?.contains(where: { $0.name == "data" && ($0.value?.isEmpty == false) }) == true
	}

	private func sendTimetableMessage(senderName: String, subjects: [Subject], completion: @escaping (Result<Void, Error>) -> Void) {
		guard let conversation = activeConversation else {
			completion(.failure(MessageSendError.noActiveConversation))
			return
		}

		let timetableData = ShareableTimetableData(sender: senderName, subjects: subjects)

		do {
			let deepLinkURL = try makeDeepLink(for: timetableData)
			let layout = MSMessageTemplateLayout()
			layout.image = TimetablePreviewRenderer.image(
				subjects: subjects,
				title: "\(senderName)'s Timetable",
				subtitle: "\(subjects.count) subjects ready to import"
			)
			layout.caption = "\(senderName)'s Timetable"
			layout.subcaption = "Tap to preview and import"

			let message = MSMessage()
			message.url = deepLinkURL
			message.layout = layout
			message.accessibilityLabel = try "TIMETABLE_PAYLOAD:\(timetableData.toBase64URL())"
			message.summaryText = "\(senderName)'s Timetable"

			conversation.insert(message) { [weak self] error in
				if let error {
					self?.insertFallbackLink(timetableData, senderName: senderName, conversation: conversation, completion: completion) ?? completion(.failure(error))
				} else {
					completion(.success(()))
				}
			}
		} catch {
			insertFallbackLink(timetableData, senderName: senderName, conversation: conversation, completion: completion)
		}
	}

	private func makeDeepLink(for timetableData: ShareableTimetableData) throws -> URL {
		let base64Data = try timetableData.toBase64URL()
		guard let deepLinkURL = makeDeepLinkFromEncodedPayload(base64Data) else {
			throw MessageSendError.invalidDeepLink
		}
		return deepLinkURL
	}

	private func makeDeepLinkFromEncodedPayload(_ payload: String) -> URL? {
		var components = URLComponents()
		components.scheme = "timetable"
		components.host = "open-timetable"
		components.fragment = payload
		return components.url
	}

	private func extractTimetablePayload(from message: MSMessage) -> String? {
		guard let label = message.accessibilityLabel else { return nil }
		let prefix = "TIMETABLE_PAYLOAD:"
		guard label.hasPrefix(prefix) else { return nil }
		return String(label.dropFirst(prefix.count))
	}

	private func insertFallbackLink(_ timetableData: ShareableTimetableData, senderName: String, conversation: MSConversation, completion: @escaping (Result<Void, Error>) -> Void) {
		do {
			let deepLinkURL = try makeDeepLink(for: timetableData)
			conversation.insertText("\(senderName)'s Timetable\n\(deepLinkURL.absoluteString)") { error in
				if let error {
					completion(.failure(error))
				} else {
					completion(.success(()))
				}
			}
		} catch {
			completion(.failure(error))
		}
	}

	private func openContainingApp(with url: URL) {
		extensionContext?.open(url, completionHandler: { [weak self] success in
			guard let self, !success else { return }
			openViaResponderChain(url)
		})
	}

	private func openViaResponderChain(_ url: URL) {
		var responder: UIResponder? = self
		while responder != nil {
			if let application = responder as? UIApplication {
				if #available(iOS 18.0, *) {
					application.open(url, options: [:], completionHandler: nil)
				} else {
					_ = application.perform(NSSelectorFromString("openURL:"), with: url)
				}
				return
			}
			responder = responder?.next
		}
	}

	private func parseAndSaveReceivedTimetable(from url: URL) {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
		      let queryItems = components.queryItems,
		      let dataParam = queryItems.first(where: { $0.name == "data" })?.value
		else {
			return
		}

		do {
			let data = try ShareableTimetableData.fromBase64URL(dataParam)

			let receivedTimetable = ReceivedTimetable(
				sender: data.sender,
				subjects: data.subjects,
				receivedAt: Date()
			)

			var existing = Defaults[.receivedTimetables]
			existing.removeAll { $0.sender == data.sender }
			existing.append(receivedTimetable)
			Defaults[.receivedTimetables] = existing
		} catch {
			print("Failed to parse received timetable: \(error)")
		}
	}
}

private enum MessageSendError: LocalizedError {
	case noActiveConversation
	case controllerDeallocated
	case invalidDeepLink

	var errorDescription: String? {
		switch self {
			case .noActiveConversation:
				"No active conversation is available."
			case .controllerDeallocated:
				"Message composer is no longer available."
			case .invalidDeepLink:
				"Could not build timetable link."
		}
	}
}

extension Color {
	init(rgba: RGBAColor) {
		self.init(red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
	}

	func toHex() -> String {
		guard let cgColor else { return "#000000" }
		guard let components = cgColor.components, components.count >= 3 else { return "#000000" }
		let r = Int(components[0] * 255)
		let g = Int(components[1] * 255)
		let b = Int(components[2] * 255)
		return String(format: "#%02X%02X%02X", r, g, b)
	}
}

extension UIImage {
	func resized(to size: CGSize) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		draw(in: CGRect(origin: .zero, size: size))
		let resized = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return resized ?? self
	}
}
