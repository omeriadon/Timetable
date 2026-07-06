import Defaults
import Foundation
import WatchConnectivity

@MainActor
@Observable
final class WatchProvisioningService: NSObject, WCSessionDelegate {
	static let shared = WatchProvisioningService()
	private(set) var isRequesting = false

	func activate() {
		guard WCSession.isSupported() else { return }
		let session = WCSession.default
		session.delegate = self
		session.activate()
	}

	func requestSessionIfPossible() {
		guard WCSession.isSupported(), !isRequesting else { return }
		let session = WCSession.default
		session.delegate = self
		if session.activationState == .notActivated {
			session.activate()
		}
		guard session.activationState == .activated, session.isReachable else {
			StatusBadgeManager.shared.addBadge(
				id: UUID(),
				title: "iPhone Unavailable",
				secondaryText: "Open Timetable on the paired iPhone and try again.",
				priority: 3,
				view: .info
			)
			return
		}
		isRequesting = true
		let installationID = Defaults[.installationID]
		session.sendMessage(["watchSessionInstallationID": installationID], replyHandler: { reply in
			Task { @MainActor in
				self.isRequesting = false
				guard let data = reply["watchSession"] as? Data,
				      let response = try? JSONDecoder().decode(TokenResponse.self, from: data)
				else {
					self.presentReplyError(reply)
					return
				}
				do {
					try await SessionStore.shared.acceptProvisionedSession(response)
					StatusBadgeManager.shared.addBadge(id: UUID(), title: "Watch Connected", priority: 3, view: .success)
				} catch {
					StatusBadgeManager.shared.present(error: error, title: "Connection Failed")
				}
			}
		}, errorHandler: { error in
			Task { @MainActor in
				self.isRequesting = false
				StatusBadgeManager.shared.present(error: error, title: "iPhone Unavailable")
			}
		})
	}

	nonisolated func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {
		Task { @MainActor in self.requestSessionIfPossible() }
	}

	nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		Task { @MainActor in
			guard let data = applicationContext["watchSession"] as? Data,
			      let response = try? JSONDecoder().decode(TokenResponse.self, from: data)
			else { return }
			try? await SessionStore.shared.acceptProvisionedSession(response)
		}
	}

	private func presentReplyError(_ reply: [String: Any]) {
		let message = reply["error"] as? String ?? "The iPhone returned an invalid session."
		StatusBadgeManager.shared.addBadge(
			id: UUID(),
			title: "Connection Failed",
			secondaryText: message,
			priority: 4,
			view: .error
		)
	}
}
