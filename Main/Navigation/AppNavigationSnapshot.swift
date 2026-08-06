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
	let timetableSubtab: TimetableSubtab
	let timetablePath: [AppRoute]
	let friendsPath: [AppRoute]
	let settingsPath: [AppRoute]
	let administrationPath: [AppRoute]
	let selectedSidebarDestination: AppRootDestination
	let sidebarPath: [AppRoute]

	init(
		selectedTab: MainTab,
		timetableSubtab: TimetableSubtab,
		timetablePath: [AppRoute],
		friendsPath: [AppRoute],
		settingsPath: [AppRoute],
		administrationPath: [AppRoute],
		selectedSidebarDestination: AppRootDestination,
		sidebarPath: [AppRoute]
	) {
		version = Self.currentVersion
		self.selectedTab = selectedTab
		self.timetableSubtab = timetableSubtab
		self.timetablePath = timetablePath
		self.friendsPath = friendsPath
		self.settingsPath = settingsPath
		self.administrationPath = administrationPath
		self.selectedSidebarDestination = selectedSidebarDestination
		self.sidebarPath = sidebarPath
	}

	private enum CodingKeys: String, CodingKey {
		case version
		case selectedTab
		case timetableSubtab
		case timetablePath
		case friendsPath
		case settingsPath
		case administrationPath
		case selectedSidebarDestination
		case sidebarPath
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		version = try container.decode(Int.self, forKey: .version)
		selectedTab = try container.decode(MainTab.self, forKey: .selectedTab)
		timetableSubtab = try container.decodeIfPresent(TimetableSubtab.self, forKey: .timetableSubtab) ?? .today
		timetablePath = try container.decode([AppRoute].self, forKey: .timetablePath)
		friendsPath = try container.decode([AppRoute].self, forKey: .friendsPath)
		settingsPath = try container.decode([AppRoute].self, forKey: .settingsPath)
		administrationPath = try container.decode([AppRoute].self, forKey: .administrationPath)
		selectedSidebarDestination = try container.decode(AppRootDestination.self, forKey: .selectedSidebarDestination)
		sidebarPath = try container.decode([AppRoute].self, forKey: .sidebarPath)
	}
}
