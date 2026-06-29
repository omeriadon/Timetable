//
//   AccountSettings.swift
//   Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation

nonisolated struct AccountSettings: Codable, Defaults.Serializable, Hashable {
	var liveActivitiesEnabled: Bool
	var notificationsEnabled: Bool

	static let `default` = AccountSettings(
		liveActivitiesEnabled: true,
		notificationsEnabled: false
	)
}
