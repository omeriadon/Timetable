import Foundation

nonisolated enum ProfileFontWeight: String, Codable, CaseIterable, Identifiable, Sendable {
	case regular
	case medium
	case semibold
	case bold
	case heavy

	var id: String {
		rawValue
	}
}
