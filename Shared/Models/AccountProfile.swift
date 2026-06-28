//
//   AccountProfile.swift
//   Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Defaults
import Foundation

struct AccountProfile: Codable, Defaults.Serializable, Hashable {
	let id: String
	let email: String?
	let displayName: String
	let createdAt: Date?
}
