import Foundation

nonisolated enum AppBackground: String, Codable, CaseIterable, Hashable, Identifiable {
	case blackPaper
	case grayPaper
	case brownPaper
	case solid
	case systemGray
	case dome
	case peak
	case tree
	case valley

	var id: Self {
		self
	}

	var title: String {
		switch self {
			case .blackPaper:
				"Black Paper"
			case .grayPaper:
				"Gray Paper"
			case .brownPaper:
				"Brown Paper"
			case .solid:
				"Solid Black or White"
			case .systemGray:
				"System Gray"
			case .dome:
				"Dome"
			case .peak:
				"Peak"
			case .tree:
				"Tree"
			case .valley:
				"Valley"
		}
	}

	var symbol: String {
		switch self {
			case .blackPaper, .grayPaper, .brownPaper:
				"doc.text.image"
			case .solid:
				"circle.lefthalf.filled"
			case .systemGray:
				"circle.fill"
			case .dome, .peak, .tree, .valley:
				"photo"
		}
	}
}
