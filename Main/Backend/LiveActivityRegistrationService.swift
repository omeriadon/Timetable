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
		private var activityUpdatesTask: Task<Void, Never>?
		private var activityTokenTasks: [String: Task<Void, Never>] = [:]
		private var activityStateTasks: [String: Task<Void, Never>] = [:]
		private var currentActivityRequestTask: Task<Void, Never>?
		private var pendingCurrentActivityRequest = false

		private init(networkManager: NetworkManager) {
			self.networkManager = networkManager
		}

		func startObserving() async {
			guard Platform.current == .iOS else { return }
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

		func reconcileAuthorization(requestStartIfNeeded: Bool = false) async {
			guard Platform.current == .iOS else { return }
			let allowed = ActivityAuthorizationInfo().areActivitiesEnabled
			let enabled = Defaults[.accountSettings].liveActivitiesEnabled
			guard allowed, enabled, SessionStore.shared.isAuthenticated else {
				stopTokenObservers()
				if SessionStore.shared.isAuthenticated {
					await endActiveActivities()
					await removeLiveActivityToken()
				}
				return
			}

			observePushToStartToken()
			observeActivityUpdates()
			observeExistingActivityTokens()
			if requestStartIfNeeded {
				pendingCurrentActivityRequest = true
			}
			if let token = Activity<SchoolDayActivityAttributes>.pushToStartToken {
				if await uploadLiveActivityPushToStartToken(token) {
					await fulfillCurrentActivityRequestIfNeeded()
				}
			}
		}

		func removeLiveActivityToken() async {
			guard Platform.current == .iOS else { return }
			guard SessionStore.shared.isAuthenticated else { return }
			do {
				try await networkManager.send(
					.v1LiveActivityTokenDelete,
					body: RemoveLiveActivityTokenRequest(installationID: ClientIdentityProvider.shared.identity().installationID)
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
					if await uploadLiveActivityPushToStartToken(token) {
						await fulfillCurrentActivityRequestIfNeeded()
					}
				}
			}
		}

		private func observeActivityUpdates() {
			guard activityUpdatesTask == nil else { return }
			activityUpdatesTask = Task { [weak self] in
				for await activity in Activity<SchoolDayActivityAttributes>.activityUpdates {
					guard let self, !Task.isCancelled else { return }
					observeTokenUpdates(for: activity)
				}
			}
		}

		private func uploadLiveActivityPushToStartToken(_ token: Data) async -> Bool {
			do {
				try await networkManager.send(
					.v1LiveActivityToken,
					body: LiveActivityPushToStartTokenRequest(
						installationID: ClientIdentityProvider.shared.identity().installationID,
						token: token.hexString,
						isDebug: Self.isDebug
					)
				)
				Print("Uploaded Live Activity push-to-start token", category: .liveActivity)
				return true
			} catch {
				PrintError("Live Activity push-to-start token upload failed", category: .liveActivity, error: error)
				return false
			}
		}

		private func observeExistingActivityTokens() {
			let activities = Activity<SchoolDayActivityAttributes>.activities
			let currentIDs = Set(activities.map(\.id))
			for (id, task) in activityTokenTasks where !currentIDs.contains(id) {
				task.cancel()
				activityTokenTasks[id] = nil
			}

			for activity in activities {
				observeTokenUpdates(for: activity)
				observeStateUpdates(for: activity)
			}
		}

		private func observeTokenUpdates(for activity: Activity<SchoolDayActivityAttributes>) {
			guard activityTokenTasks[activity.id] == nil else { return }
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

		private func observeStateUpdates(for activity: Activity<SchoolDayActivityAttributes>) {
			guard activityStateTasks[activity.id] == nil else { return }
			activityStateTasks[activity.id] = Task { [weak self] in
				for await state in activity.activityStateUpdates {
					guard !Task.isCancelled else { return }
					if state == .ended || state == .dismissed {
						self?.removeActivityObservers(for: activity.id)
						return
					}
				}
			}
		}

		private func removeActivityObservers(for id: String) {
			activityTokenTasks[id]?.cancel()
			activityTokenTasks[id] = nil
			activityStateTasks[id]?.cancel()
			activityStateTasks[id] = nil
		}

		private func fulfillCurrentActivityRequestIfNeeded() async {
			guard pendingCurrentActivityRequest else { return }
			if let currentActivityRequestTask {
				await currentActivityRequestTask.value
				return
			}
			let task = Task { @MainActor in
				await self.performCurrentActivityRequest()
			}
			currentActivityRequestTask = task
			await task.value
			currentActivityRequestTask = nil
		}

		private func performCurrentActivityRequest() async {
			do {
				let response: ReconcileLiveActivityResponse = try await networkManager.send(
					.v1LiveActivityReconcile,
					body: ReconcileLiveActivityRequest(installationID: ClientIdentityProvider.shared.identity().installationID)
				)
				Print(
					response.started ? "Requested current Live Activity" : "Current Live Activity not required",
					category: .liveActivity
				)
				pendingCurrentActivityRequest = false
			} catch {
				PrintError("Live Activity reconciliation failed", category: .liveActivity, error: error)
			}
		}

		private func uploadUpdateToken(_ token: Data, activityKey: String) async {
			do {
				try await networkManager.send(
					.v1LiveActivityUpdateToken(activityKey: activityKey),
					body: LiveActivityUpdateTokenRequest(
						installationID: ClientIdentityProvider.shared.identity().installationID,
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
			activityUpdatesTask?.cancel()
			activityUpdatesTask = nil
			pendingCurrentActivityRequest = false
			for task in activityTokenTasks.values {
				task.cancel()
			}
			activityTokenTasks.removeAll()
			for task in activityStateTasks.values {
				task.cancel()
			}
			activityStateTasks.removeAll()
		}

		private func endActiveActivities() async {
			for activity in Activity<SchoolDayActivityAttributes>.activities {
				await activity.end(nil, dismissalPolicy: .immediate)
			}
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
		static let v1LiveActivityReconcile = Endpoint("/v1/live-activities/current/reconcile", method: .post)

		static func v1LiveActivityUpdateToken(activityKey: String) -> Endpoint {
			Endpoint("/v1/live-activities/\(activityKey)/update-token", method: .put)
		}
	}
#endif
