import Foundation

nonisolated enum ProfileContentKind: String, Codable, CaseIterable, Sendable {
	case photo
	case monogram
	case emoji
}
