//
//  StatusBadgeManager.swift
//  App Shared
//

import Defaults
import Foundation
import Observation
import SwiftUI

#if os(iOS)
	import UIKit
#elseif os(watchOS)
	import WatchKit
#endif

enum HapticEvent {
	case button
	case selection
	case success
	case warning
	case error
}

@MainActor
final class HapticManager {
	static let shared = HapticManager()

	private init() {}

	func play(_ event: HapticEvent) {
		guard Defaults[.hapticsEnabled] else { return }

		#if os(iOS)
			switch event {
				case .button, .selection:
					let generator = UISelectionFeedbackGenerator()
					generator.prepare()
					generator.selectionChanged()
				case .success, .warning, .error:
					let generator = UINotificationFeedbackGenerator()
					generator.prepare()
					let type: UINotificationFeedbackGenerator.FeedbackType
					switch event {
						case .success: type = .success
						case .warning: type = .warning
						case .error: type = .error
						default: type = .success
					}
					generator.notificationOccurred(type)
			}
		#elseif os(watchOS)
			let type: WKHapticType = switch event {
				case .button, .selection: .click
				case .success: .success
				case .warning: .retry
				case .error: .failure
			}
			WKInterfaceDevice.current().play(type)
		#endif
	}
}

enum StatusBadgeView: Equatable {
	case progressView
	case success
	case error
	case warning
	case info
	case progressViewAndGauge(currentStep: Int, totalSteps: Int)

	fileprivate var rank: Int {
		switch self {
			case .error: 4
			case .success: 3
			case .warning, .info: 2
			case .progressView, .progressViewAndGauge: 1
		}
	}

	var showsProgressBackground: Bool {
		switch self {
			case .progressView, .progressViewAndGauge:
				true
			default:
				false
		}
	}
}

struct StatusBadge: Identifiable, Equatable {
	let id: UUID
	var title: String
	var secondaryText: String?
	var priority: Int
	var view: StatusBadgeView
	let sequence: UInt64
}

@MainActor
@Observable
final class StatusBadgeManager {
	static let shared = StatusBadgeManager()

	private(set) var badges: [StatusBadge] = []
	private(set) var activeBadgeID: UUID?
	private let offlineDuration: Duration = .seconds(1)

	@ObservationIgnored private var nextSequence: UInt64 = 0
	@ObservationIgnored private var removalTasks: [UUID: Task<Void, Never>] = [:]

	var mainBadge: StatusBadge? {
		if let activeBadgeID,
		   let active = badges.first(where: { $0.id == activeBadgeID })
		{
			return active
		}
		return nil
	}

	func addBadge(
		id: UUID,
		title: String,
		secondaryText: String? = nil,
		priority: Int,
		view: StatusBadgeView
	) {
		if view == .success { HapticManager.shared.play(.success) }
		if view == .error { HapticManager.shared.play(.error) }
		if view == .warning { HapticManager.shared.play(.warning) }
		Print(title)
		Print(secondaryText ?? "")
		if let index = badges.firstIndex(where: { $0.id == id }) {
			guard badges[index].view != .success else { return }
			removalTasks[id]?.cancel()
			removalTasks[id] = nil
			badges[index].title = title
			badges[index].secondaryText = secondaryText
			badges[index].priority = min(max(priority, 1), 5)
			badges[index].view = view
		} else {
			nextSequence += 1
			badges.append(
				StatusBadge(
					id: id,
					title: title,
					secondaryText: secondaryText,
					priority: min(max(priority, 1), 5),
					view: view,
					sequence: nextSequence
				)
			)
		}

		activateNextBadgeIfNeeded()
		scheduleRemovalIfNeeded(for: id, view: view)
	}

	func updateBadge(
		id: UUID,
		title: String,
		secondaryText: String? = nil,
		view: StatusBadgeView
	) {
		guard let index = badges.firstIndex(where: { $0.id == id }),
		      badges[index].view != .success
		else { return }

		removalTasks[id]?.cancel()
		removalTasks[id] = nil
		badges[index].title = title
		badges[index].secondaryText = secondaryText
		badges[index].view = view
		if view == .success { HapticManager.shared.play(.success) }
		if view == .error { HapticManager.shared.play(.error) }
		if view == .warning { HapticManager.shared.play(.warning) }

		scheduleRemovalIfNeeded(for: id, view: view)
	}

	func dismissMainBadge() {
		guard let mainBadge else { return }
		removeBadge(id: mainBadge.id)
	}

	func offline() {
		let id = UUID()
		addBadge(id: id, title: "No Internet Connection", secondaryText: "Connect to the internet and try again.", priority: 3, view: .info)
		scheduleRemoval(for: id, after: offlineDuration)
	}

	func signInRequired() {
		addBadge(id: UUID(), title: "Sign In Required", secondaryText: "Sign in to use this feature.", priority: 3, view: .info)
	}

	func present(networkError: NetworkError, title: String = "Network Error") {
		switch networkError {
			case .offline: offline()
			case .authenticationRequired: signInRequired()
			case .cancelled: break
			default: addBadge(id: UUID(), title: title, secondaryText: networkError.localizedDescription, priority: 4, view: .error)
		}
	}

	func present(error: any Error, title: String) {
		if let networkError = error as? NetworkError { present(networkError: networkError, title: title); return }
		addBadge(id: UUID(), title: title, secondaryText: error.localizedDescription, priority: 4, view: .error)
	}

	private var rankedBadges: [StatusBadge] {
		badges.sorted {
			if $0.view.rank != $1.view.rank { return $0.view.rank > $1.view.rank }
			if $0.priority != $1.priority { return $0.priority > $1.priority }
			return $0.sequence < $1.sequence
		}
	}

	private func activateNextBadgeIfNeeded() {
		guard activeBadgeID == nil else { return }
		activeBadgeID = rankedBadges.first?.id
		guard let mainBadge else { return }
		scheduleRemovalIfNeeded(for: mainBadge.id, view: mainBadge.view)
	}

	private func scheduleRemovalIfNeeded(for id: UUID, view: StatusBadgeView) {
		guard activeBadgeID == id else { return }
		let duration: Duration
		switch view {
			case .success:
				duration = .seconds(2)
			case .error, .warning, .info:
				duration = .seconds(5)
			default:
				return
		}

		scheduleRemoval(for: id, after: duration)
	}

	private func scheduleRemoval(for id: UUID, after duration: Duration) {
		removalTasks[id]?.cancel()
		removalTasks[id] = Task { [weak self] in
			do {
				try await Task.sleep(for: duration)
			} catch {
				return
			}
			guard !Task.isCancelled else { return }
			self?.removeBadge(id: id)
		}
	}

	private func removeBadge(id: UUID) {
		removalTasks[id]?.cancel()
		removalTasks[id] = nil
		badges.removeAll(where: { $0.id == id })
		if activeBadgeID == id {
			activeBadgeID = nil
			activateNextBadgeIfNeeded()
		}
	}
}

extension EnvironmentValues {
	@Entry var statusBadgeManager: StatusBadgeManager = .shared
}
