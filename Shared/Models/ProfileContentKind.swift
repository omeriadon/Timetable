import Foundation

nonisolated enum ProfileContentKind: String, Codable, CaseIterable, Hashable, Sendable {
	case photo
	case monogram
	case emoji
}
