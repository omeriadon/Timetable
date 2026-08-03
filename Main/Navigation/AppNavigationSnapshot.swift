import Foundation
import SwiftUI

enum AppSidebarVisibility: String, Codable, Hashable, Sendable {
	case automatic
	case all
	case detailOnly

	init(_ visibility: NavigationSplitViewVisibility) {
		switch visibility {
			case .all:
				self = .all
			case .detailOnly:
				self = .detailOnly
			default:
				self = .automatic
		}
	}

	var navigationSplitViewVisibility: NavigationSplitViewVisibility {
		switch self {
			case .automatic:
				.automatic
			case .all:
				.all
			case .detailOnly:
				.detailOnly
		}
	}
}

struct AppNavigationSnapshot: Codable, Equatable, Sendable {
	static let currentVersion = 1

	let version: Int
	let selectedTab: MainTab
	let timetablePath: [AppRoute]
	let friendsPath: [AppRoute]
	let settingsPath: [AppRoute]
	let administrationPath: [AppRoute]
	let selectedSidebarDestination: AppRootDestination
	let sidebarPath: [AppRoute]

	init(
		selectedTab: MainTab,
		timetablePath: [AppRoute],
		friendsPath: [AppRoute],
		settingsPath: [AppRoute],
		administrationPath: [AppRoute],
		selectedSidebarDestination: AppRootDestination,
		sidebarPath: [AppRoute]
	) {
		version = Self.currentVersion
		self.selectedTab = selectedTab
		self.timetablePath = timetablePath
		self.friendsPath = friendsPath
		self.settingsPath = settingsPath
		self.administrationPath = administrationPath
		self.selectedSidebarDestination = selectedSidebarDestination
		self.sidebarPath = sidebarPath
	}
}
