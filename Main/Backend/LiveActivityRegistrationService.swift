#if os(iOS)
	import ActivityKit
	import Defaults
	import Foundation
	import Observation

	@MainActor
	@Observable
	final class LiveActivityRegistrationService {
		static let shared = LiveActivityRegistrationService(networkManager: .shared)

		private let networkManager: NetworkManager
		private var authorizationTask: Task<Void, Never>?
		private var pushToStartTask: Task<Void, Never>?
		private var activityTokenTasks: [String: Task<Void, Never>] = [:]

		private init(networkManager: NetworkManager) {
			self.networkManager = networkManager
		}

		func startObserving() async {
			guard authorizationTask == nil else {
				await reconcileAuthorization()
				return
			}

			authorizationTask = Task { [weak self] in
				let authorization = ActivityAuthorizationInfo()
				for await _ in authorization.activityEnablementUpdates {
					guard let self, !Task.isCancelled else { return }
					await reconcileAuthorization()
				}
			}
			await reconcileAuthorization()
		}

		func reconcileAuthorization() async {
			let allowed = ActivityAuthorizationInfo().areActivitiesEnabled
			let enabled = Defaults[.accountSettings].liveActivitiesEnabled
			guard allowed, enabled, SessionStore.shared.isAuthenticated else {
				stopTokenObservers()
				if SessionStore.shared.isAuthenticated {
					await removeLiveActivityToken()
				}
				return
			}

			observePushToStartToken()
			observeExistingActivityTokens()
			if let token = Activity<SchoolDayActivityAttributes>.pushToStartToken {
				await uploadLiveActivityPushToStartToken(token)
			}
		}

		func removeLiveActivityToken() async {
			guard SessionStore.shared.isAuthenticated else { return }
			do {
				try await networkManager.send(
					.v1LiveActivityTokenDelete,
					body: RemoveLiveActivityTokenRequest(installationID: Defaults[.installationID])
				)
			} catch {
				PrintError("Live Activity token removal failed", category: .liveActivity, error: error)
			}
		}

		private func observePushToStartToken() {
			guard pushToStartTask == nil else { return }
			pushToStartTask = Task { [weak self] in
				for await token in Activity<SchoolDayActivityAttributes>.pushToStartTokenUpdates {
					guard let self, !Task.isCancelled else { return }
					await uploadLiveActivityPushToStartToken(token)
				}
			}
		}

		private func uploadLiveActivityPushToStartToken(_ token: Data) async {
			do {
				try await networkManager.send(
					.v1LiveActivityToken,
					body: LiveActivityPushToStartTokenRequest(
						installationID: Defaults[.installationID],
						token: token.hexString,
						isDebug: Self.isDebug
					)
				)
				Print("Uploaded Live Activity push-to-start token", category: .liveActivity)
			} catch {
				PrintError("Live Activity push-to-start token upload failed", category: .liveActivity, error: error)
			}
		}

		private func observeExistingActivityTokens() {
			let activities = Activity<SchoolDayActivityAttributes>.activities
			let currentIDs = Set(activities.map(\.id))
			for (id, task) in activityTokenTasks where !currentIDs.contains(id) {
				task.cancel()
				activityTokenTasks[id] = nil
			}

			for activity in activities where activityTokenTasks[activity.id] == nil {
				activityTokenTasks[activity.id] = Task { [weak self] in
					if let token = activity.pushToken {
						await self?.uploadUpdateToken(token, activityKey: activity.attributes.activityKey)
					}
					for await token in activity.pushTokenUpdates {
						guard !Task.isCancelled else { return }
						await self?.uploadUpdateToken(token, activityKey: activity.attributes.activityKey)
					}
				}
			}
		}

		private func uploadUpdateToken(_ token: Data, activityKey: String) async {
			do {
				try await networkManager.send(
					.v1LiveActivityUpdateToken(activityKey: activityKey),
					body: LiveActivityUpdateTokenRequest(
						installationID: Defaults[.installationID],
						token: token.hexString,
						isDebug: Self.isDebug
					)
				)
			} catch {
				PrintError("Live Activity update token upload failed", category: .liveActivity, error: error)
			}
		}

		private func stopTokenObservers() {
			pushToStartTask?.cancel()
			pushToStartTask = nil
			for task in activityTokenTasks.values {
				task.cancel()
			}
			activityTokenTasks.removeAll()
		}

		private static var isDebug: Bool {
			#if DEBUG
				true
			#else
				false
			#endif
		}
	}

	private extension Data {
		var hexString: String {
			map { String(format: "%02x", $0) }.joined()
		}
	}

	private extension Endpoint {
		static let v1LiveActivityToken = Endpoint("/v1/devices/current/live-activity-token", method: .put)
		static let v1LiveActivityTokenDelete = Endpoint("/v1/devices/current/live-activity-token", method: .delete)

		static func v1LiveActivityUpdateToken(activityKey: String) -> Endpoint {
			Endpoint("/v1/live-activities/\(activityKey)/update-token", method: .put)
		}
	}
#endif
