import Messages
import Security
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
	private let sendButton = UIButton(type: .system)
	private let statusLabel = UILabel()
	private let suite = UserDefaults(suiteName: "group.omeriadon.timetable") ?? .standard

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		sendButton.configuration = .filled()
		sendButton.configuration?.title = "Send Timetable"
		sendButton.configuration?.image = UIImage(systemName: "paperplane.fill")
		sendButton.configuration?.imagePadding = 8
		sendButton.addTarget(self, action: #selector(sendTimetable), for: .touchUpInside)
		statusLabel.textAlignment = .center
		statusLabel.font = .preferredFont(forTextStyle: .headline)
		statusLabel.numberOfLines = 0
		let stack = UIStackView(arrangedSubviews: [sendButton, statusLabel])
		stack.axis = .vertical
		stack.spacing = 18
		stack.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(stack)
		NSLayoutConstraint.activate([
			stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
			stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
		])
	}

	override func willBecomeActive(with conversation: MSConversation) {
		super.willBecomeActive(with: conversation)
		guard let message = conversation.selectedMessage,
		      let locator = Self.locator(from: message.url)
		else { return }
		let title = (message.layout as? MSMessageTemplateLayout)?.caption ?? "Shared Timetable"
		confirmImport(locator: locator, title: title)
	}

	@objc private func sendTimetable() {
		guard let value = suite.string(forKey: "ownerTimetableID"), let id = UUID(uuidString: value) else {
			showStatus("Open Timetable and finish syncing before sharing.", success: false)
			return
		}
		let title = suite.string(forKey: "userDisplayName").map { "\($0)'s Timetable" } ?? "Shared Timetable"
		let previewTitle = String(title.prefix(80))
		let locator = suite.string(forKey: "ownerTimetableShareAlias").flatMap { $0.isEmpty ? nil : $0 } ?? id.uuidString
		var components = URLComponents(string: "https://timetable.adonis.pt/share/\(locator)")!
		components.queryItems = [
			URLQueryItem(name: "title", value: previewTitle),
			URLQueryItem(name: "sharedAt", value: ISO8601DateFormatter().string(from: .now)),
		]
		let layout = MSMessageTemplateLayout()
		layout.caption = previewTitle
		layout.subcaption = "Tap to preview and save this timetable"
		layout.image = UIImage(systemName: "calendar.day.timeline.left")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
		let message = MSMessage(session: MSSession())
		message.layout = layout
		message.url = components.url
		message.summaryText = previewTitle
		activeConversation?.insert(message) { [weak self] error in
			DispatchQueue.main.async {
				self?.showStatus(error == nil ? "Timetable added to the message." : "Unable to add timetable.", success: error == nil)
			}
		}
	}

	private func confirmImport(locator: String, title: String) {
		guard presentedViewController == nil else { return }
		let alert = UIAlertController(title: "Save \(title)?", message: "This adds the timetable to your received timetables on every signed-in device.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
			self?.importTimetable(locator: locator)
		})
		present(alert, animated: true)
	}

	private func importTimetable(locator: String) {
		sendButton.isEnabled = false
		Task {
			let imported = await submitImport(locator: locator)
			await MainActor.run {
				if !imported {
					enqueue(locator)
				}
				showStatus(imported ? "Timetable saved." : "Timetable queued. Open the app to finish saving it.", success: true)
				sendButton.isEnabled = true
			}
		}
	}

	private func submitImport(locator: String) async -> Bool {
		guard let token = accessToken() else { return false }
		var request = URLRequest(url: URL(string: "https://timetable.adonis.pt/v1/timetables/received/import")!)
		request.httpMethod = "POST"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		let body: [String: String] = if let id = UUID(uuidString: locator) {
			["timetableID": id.uuidString]
		} else {
			["timetableLocator": locator]
		}
		request.httpBody = try? JSONEncoder().encode(body)
		do {
			let (_, response) = try await URLSession.shared.data(for: request)
			return (response as? HTTPURLResponse).map { (200 ... 299).contains($0.statusCode) } ?? false
		} catch {
			return false
		}
	}

	private func enqueue(_ locator: String) {
		var pending = suite.stringArray(forKey: "pendingMessageTimetableLocators") ?? []
		if !pending.contains(locator) {
			pending.append(locator)
		}
		suite.set(pending, forKey: "pendingMessageTimetableLocators")
	}

	private func accessToken() -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: "com.omeriadon.Timetable.session.accessToken",
			kSecAttrService as String: "com.omeriadon.Timetable",
			kSecAttrAccessGroup as String: "P6PV2R9443.com.omeriadon.Timetable.keychain.shared",
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]
		var result: AnyObject?
		guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
		      let data = result as? Data
		else { return nil }
		return String(data: data, encoding: .utf8)
	}

	private func showStatus(_ text: String, success: Bool) {
		statusLabel.text = success ? "✓ \(text)" : text
		statusLabel.textColor = success ? .systemGreen : .secondaryLabel
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(2))
			statusLabel.text = nil
		}
	}

	private static func locator(from url: URL?) -> String? {
		guard let url, url.host == "timetable.adonis.pt",
		      url.pathComponents.count >= 3,
		      url.pathComponents[1] == "share"
		else { return nil }
		let locator = url.pathComponents[2]
		guard locator.utf8.count <= 30 else { return nil }
		return locator
	}
}
