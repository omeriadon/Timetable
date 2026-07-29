import Foundation

nonisolated enum ProfileFontDesign: String, Codable, CaseIterable, Identifiable, Sendable {
	case `default`
	case serif
	case monospaced
	case rounded

	var id: String {
		rawValue
	}
}
