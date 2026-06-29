//
//  StatusBadgeManager.swift
//  Timetable
//

import Foundation
import Observation
import SwiftUI

enum StatusBadgeView: Equatable {
	case progressView(secondaryText: String)
	case success
	case error
	case warning
	case circularGague(currentStep: Int, totalSteps: Int, secondaryText: String)
	case progressViewAndGague(currentStep: Int, totalSteps: Int, secondaryText: String)

	var secondaryText: String? {
		switch self {
			case let .progressView(secondaryText),
			     let .circularGague(_, _, secondaryText),
			     let .progressViewAndGague(_, _, secondaryText):
				secondaryText
			case .success, .error, .warning:
				nil
		}
	}

	fileprivate var rank: Int {
		switch self {
			case .error: 4
			case .success: 3
			case .warning: 2
			case .progressView, .circularGague, .progressViewAndGague: 1
		}
	}
}

struct StatusBadge: Identifiable, Equatable {
	let id: UUID
	var title: String
	var priority: Int
	var view: StatusBadgeView
	let sequence: UInt64

	var dismissible: Bool {
		if case .circularGague = view { return false }
		return true
	}
}

@MainActor
@Observable
final class StatusBadgeManager {
	static let shared = StatusBadgeManager()

	private(set) var badges: [StatusBadge] = []
	private(set) var activeBadgeID: UUID?

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
		priority: Int,
		view: StatusBadgeView
	) {
		if let index = badges.firstIndex(where: { $0.id == id }) {
			guard badges[index].view != .success else { return }
			removalTasks[id]?.cancel()
			removalTasks[id] = nil
			badges[index].title = title
			badges[index].priority = min(max(priority, 1), 5)
			badges[index].view = view
		} else {
			nextSequence += 1
			badges.append(
				StatusBadge(
					id: id,
					title: title,
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
		view: StatusBadgeView
	) {
		guard let index = badges.firstIndex(where: { $0.id == id }),
		      badges[index].view != .success
		else { return }

		removalTasks[id]?.cancel()
		removalTasks[id] = nil
		badges[index].title = title
		badges[index].view = view

		scheduleRemovalIfNeeded(for: id, view: view)
	}

	func dismissMainBadge() {
		guard let mainBadge, mainBadge.dismissible else { return }
		removeBadge(id: mainBadge.id)
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
			case .error, .warning:
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
