import Foundation

nonisolated enum AccountAuthority: String, Codable, CaseIterable, Hashable, Sendable {
	case user
	case administrator
	case systemOwner

	var isAdministrator: Bool {
		switch self {
			case .user:
				false
			case .administrator, .systemOwner:
				true
		}
	}
}
