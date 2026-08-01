import Foundation

enum ProfilePhotoSelectionError: LocalizedError {
	case unreadableImage
	case encodingFailed

	var errorDescription: String? {
		switch self {
			case .unreadableImage:
				"The selected photo could not be read."
			case .encodingFailed:
				"The selected photo could not be prepared."
		}
	}
}
