import Foundation

enum ProfilePhotoSelectionState: Equatable {
	case idle
	case loading
	case ready
	case failed(String)
}
