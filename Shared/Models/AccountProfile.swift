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
	let email: String
	let displayName: String
	let createdAt: Date?
	let authority: AccountAuthority
	let appearance: ProfileAppearance
	let photo: ProfilePhotoMetadata?
	let badges: [ProfileBadge]
	let revision: Int

	private enum CodingKeys: String, CodingKey {
		case id
		case email
		case displayName
		case createdAt
		case authority
		case appearance
		case photo
		case badges
		case revision
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		email = try container.decode(String.self, forKey: .email)
		displayName = try container.decode(String.self, forKey: .displayName)
		createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
		authority = try container.decodeIfPresent(AccountAuthority.self, forKey: .authority) ?? .user
		appearance = try container.decodeIfPresent(ProfileAppearance.self, forKey: .appearance) ?? .default
		photo = try container.decodeIfPresent(ProfilePhotoMetadata.self, forKey: .photo)
		badges = try container.decodeIfPresent([ProfileBadge].self, forKey: .badges) ?? []
		revision = try container.decodeIfPresent(Int.self, forKey: .revision) ?? 0
	}
}
