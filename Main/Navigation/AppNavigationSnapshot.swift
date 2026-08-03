import Foundation

enum AppSidebarVisibility: String, Codable, Hashable, Sendable {
	case automatic
	case all
	case detailOnly
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
	let sidebarVisibility: AppSidebarVisibility

	init(
		selectedTab: MainTab,
		timetablePath: [AppRoute],
		friendsPath: [AppRoute],
		settingsPath: [AppRoute],
		administrationPath: [AppRoute],
		selectedSidebarDestination: AppRootDestination,
		sidebarPath: [AppRoute],
		sidebarVisibility: AppSidebarVisibility
	) {
		version = Self.currentVersion
		self.selectedTab = selectedTab
		self.timetablePath = timetablePath
		self.friendsPath = friendsPath
		self.settingsPath = settingsPath
		self.administrationPath = administrationPath
		self.selectedSidebarDestination = selectedSidebarDestination
		self.sidebarPath = sidebarPath
		self.sidebarVisibility = sidebarVisibility
	}
}
