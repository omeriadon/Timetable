//
//  MessagesViewController.swift
//  PMS Timetable Message Extension
//
//  Created by Adon Omeri on 29/4/2026.
//

import UIKit
import Messages
import SwiftUI
import Defaults

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
		let view: any View
		if hasSelectedMessage || messageURL != nil || fallbackPayload != nil {
			view = AnyView(
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
			view = AnyView(TranscriptPlaceholder())
		} else {
			view = AnyView(
				TimetableView { [weak self] _, classes, completion in
					guard let self else {
						completion(.failure(MessageSendError.controllerDeallocated))
						return
					}
					self.sendTimetableMessage(senderName: userDisplayName, classes: classes, completion: completion)
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
			newController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
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
					provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, _ in
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
		guard url.scheme == "pmstimetable" else { return false }
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		let hasData = components?.queryItems?.contains(where: { $0.name == "data" && ($0.value?.isEmpty == false) }) == true
		return hasData
	}


	private func sendTimetableMessage(senderName: String, classes: [Class], completion: @escaping (Result<Void, Error>) -> Void) {
		guard let conversation = activeConversation else {
			completion(.failure(MessageSendError.noActiveConversation))
			return
		}

		let shareableClasses = classes.map { classItem in
			ShareableClass(
				name: classItem.id,
				symbol: classItem.symbol,
				color: String(format: "#%02X%02X%02X", Int(classItem.colour.r * 255), Int(classItem.colour.g * 255), Int(classItem.colour.b * 255)),
				slots: classItem.slots.map { ShareableSlot(day: $0.day, period: $0.session) }
			)
		}

		let timetableData = ShareableTimetableData(sender: senderName, classes: shareableClasses)

		do {
			let deepLinkURL = try makeDeepLink(for: timetableData)
			let layout = MSMessageTemplateLayout()
			layout.image = makeTimetablePreviewImage(classes: classes, senderName: senderName)
			layout.imageTitle = "\(senderName)'s Timetable"
			layout.imageSubtitle = "\(classes.count) classes"
			layout.caption = "PMS Timetable"
			layout.subcaption = "Tap to preview and import"
			layout.trailingCaption = "Import"
			layout.trailingSubcaption = "Shared"

			let message = MSMessage()
			message.url = deepLinkURL
			message.layout = layout
			message.accessibilityLabel = "PMS_TIMETABLE_PAYLOAD:\(try timetableData.toBase64URL())"
			message.summaryText = "\(senderName)'s PMS Timetable"

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
		components.scheme = "pmstimetable"
		components.host = "open-timetable"
		components.fragment = payload
		return components.url
	}

	private func extractTimetablePayload(from message: MSMessage) -> String? {
		guard let label = message.accessibilityLabel else { return nil }
		let prefix = "PMS_TIMETABLE_PAYLOAD:"
		guard label.hasPrefix(prefix) else { return nil }
		return String(label.dropFirst(prefix.count))
	}

	private func makeTimetablePreviewImage(classes: [Class], senderName: String) -> UIImage {
		let size = CGSize(width: 900, height: 520)
		let renderer = UIGraphicsImageRenderer(size: size)
		let displayClasses = Array(classes.prefix(6))

		return renderer.image { context in
			let cgContext = context.cgContext
			let rect = CGRect(origin: .zero, size: size)
			UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1).setFill()
			cgContext.fill(rect)

			let headerAttributes: [NSAttributedString.Key: Any] = [
				.font: UIFont.monospacedSystemFont(ofSize: 44, weight: .bold),
				.foregroundColor: UIColor.white
			]
			let subheadAttributes: [NSAttributedString.Key: Any] = [
				.font: UIFont.monospacedSystemFont(ofSize: 24, weight: .medium),
				.foregroundColor: UIColor.white.withAlphaComponent(0.68)
			]

			("\(senderName)'s timetable" as NSString).draw(at: CGPoint(x: 44, y: 38), withAttributes: headerAttributes)
			("\(classes.count) classes ready to import" as NSString).draw(at: CGPoint(x: 46, y: 96), withAttributes: subheadAttributes)

			let columns = 3
			let cardWidth: CGFloat = 252
			let cardHeight: CGFloat = 112
			let gap: CGFloat = 24
			let startX: CGFloat = 44
			let startY: CGFloat = 164

			for (index, classItem) in displayClasses.enumerated() {
				let row = index / columns
				let column = index % columns
				let cardRect = CGRect(
					x: startX + CGFloat(column) * (cardWidth + gap),
					y: startY + CGFloat(row) * (cardHeight + gap),
					width: cardWidth,
					height: cardHeight
				)

				let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 22)
				UIColor.white.withAlphaComponent(0.10).setFill()
				path.fill()

				let stripeRect = CGRect(x: cardRect.minX, y: cardRect.minY, width: 12, height: cardRect.height)
				let stripePath = UIBezierPath(
					roundedRect: stripeRect,
					byRoundingCorners: [.topLeft, .bottomLeft],
					cornerRadii: CGSize(width: 22, height: 22)
				)
				UIColor(classItem.colour.swiftUIColor).setFill()
				stripePath.fill()

				let titleAttributes: [NSAttributedString.Key: Any] = [
					.font: UIFont.monospacedSystemFont(ofSize: 25, weight: .semibold),
					.foregroundColor: UIColor.white
				]
				let detailAttributes: [NSAttributedString.Key: Any] = [
					.font: UIFont.monospacedSystemFont(ofSize: 19, weight: .regular),
					.foregroundColor: UIColor.white.withAlphaComponent(0.62)
				]

				(classItem.id as NSString).draw(
					in: CGRect(x: cardRect.minX + 28, y: cardRect.minY + 22, width: cardRect.width - 44, height: 32),
					withAttributes: titleAttributes
				)
				("\(classItem.slots.count) slot\(classItem.slots.count == 1 ? "" : "s")" as NSString).draw(
					at: CGPoint(x: cardRect.minX + 28, y: cardRect.minY + 62),
					withAttributes: detailAttributes
				)
			}

			if classes.count > displayClasses.count {
				let moreAttributes: [NSAttributedString.Key: Any] = [
					.font: UIFont.monospacedSystemFont(ofSize: 22, weight: .medium),
					.foregroundColor: UIColor.white.withAlphaComponent(0.72)
				]
				("+\(classes.count - displayClasses.count) more classes" as NSString).draw(
					at: CGPoint(x: 46, y: 456),
					withAttributes: moreAttributes
				)
			}
		}
	}

	private func insertFallbackLink(_ timetableData: ShareableTimetableData, senderName: String, conversation: MSConversation, completion: @escaping (Result<Void, Error>) -> Void) {
		do {
			let deepLinkURL = try makeDeepLink(for: timetableData)
			conversation.insertText("\(senderName)'s PMS Timetable\n\(deepLinkURL.absoluteString)") { error in
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
			self.openViaResponderChain(url)
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
			  let dataParam = queryItems.first(where: { $0.name == "data" })?.value else {
			return
		}
		
		do {
			let data = try ShareableTimetableData.fromBase64URL(dataParam)
			
			let classes = data.classes.map { shareableClass in
				Class(
					id: shareableClass.name,
					symbol: shareableClass.symbol,
					colour: RGBAColor(hexString: shareableClass.color),
					slots: shareableClass.slots.map { Slot($0.day, $0.period) }
				)
			}
			
			let receivedTimetable = ReceivedTimetable(
				sender: data.sender,
				classes: classes,
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
			return "No active conversation is available."
		case .controllerDeallocated:
			return "Message composer is no longer available."
		case .invalidDeepLink:
			return "Could not build timetable link."
		}
	}
}

extension Color {
	init(rgba: RGBAColor) {
		self.init(red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
	}
	
	func toHex() -> String {
		guard let cgColor = self.cgColor else { return "#000000" }
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
		self.draw(in: CGRect(origin: .zero, size: size))
		let resized = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return resized ?? self
	}
}
