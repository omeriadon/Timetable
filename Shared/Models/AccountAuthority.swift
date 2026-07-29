import Foundation

nonisolated enum AccountAuthority: String, Codable, CaseIterable, Hashable, Sendable {
	case user
	case administrator
	case systemOwner
}
