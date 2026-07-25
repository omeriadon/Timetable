import Foundation
import Messages
import Observation
import Security

@MainActor
@Observable
final class MessagesViewModel {
	private static let maximumShareLocatorLength = 36
	private let suite = UserDefaults(suiteName: "group.omeriadon.timetable") ?? .standard
	private var conversation: MSConversation?
	private var statusTask: Task<Void, Never>?

	var importPrompt: ImportPrompt?
	var isImporting = false
	var status: Status?

	func becomeActive(with conversation: MSConversation) {
		self.conversation = conversation
		guard let message = conversation.selectedMessage,
		      let locator = Self.locator(from: message.url)
		else { return }
		let title = (message.layout as? MSMessageTemplateLayout)?.caption ?? "Shared Timetable"
		importPrompt = ImportPrompt(locator: locator, title: title)
	}

	func sendTimetable() {
		guard let value = suite.string(forKey: "ownerTimetableID"), let id = UUID(uuidString: value) else {
			showStatus("Open Timetable and finish syncing before sharing.", isSuccess: false)
			return
		}

		let locator = suite.string(forKey: "ownerTimetableShareAlias").flatMap { $0.isEmpty ? nil : $0 } ?? id.uuidString
		let url = URL(string: "https://timetable.adonis.pt/share/\(locator)")!
		conversation?.insertText(url.absoluteString) { [weak self] error in
			Task { @MainActor in
				self?.showStatus(error == nil ? "Link added to the message." : "Unable to add link.", isSuccess: error == nil)
			}
		}
	}

	func dismissImport() {
		importPrompt = nil
	}

	func importTimetable() {
		guard let prompt = importPrompt else { return }
		importPrompt = nil
		isImporting = true

		Task {
			let imported = await submitImport(locator: prompt.locator)
			if !imported {
				enqueue(prompt.locator)
			}
			showStatus(imported ? "Timetable saved." : "Timetable queued. Open the app to finish saving it.", isSuccess: true)
			isImporting = false
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

	private func showStatus(_ text: String, isSuccess: Bool) {
		statusTask?.cancel()
		status = Status(text: text, isSuccess: isSuccess)
		statusTask = Task { [weak self] in
			try? await Task.sleep(for: .seconds(2))
			guard !Task.isCancelled else { return }
			self?.status = nil
		}
	}

	private static func locator(from url: URL?) -> String? {
		guard let url, url.host == "timetable.adonis.pt",
		      url.pathComponents.count >= 3,
		      ["share", "sharedtimetable"].contains(url.pathComponents[1])
		else { return nil }
		let locator = url.pathComponents[2]
		guard locator.utf8.count <= maximumShareLocatorLength else { return nil }
		return locator
	}
}

extension MessagesViewModel {
	struct ImportPrompt: Identifiable {
		let id = UUID()
		let locator: String
		let title: String
	}

	struct Status: Equatable {
		let text: String
		let isSuccess: Bool
	}
}
