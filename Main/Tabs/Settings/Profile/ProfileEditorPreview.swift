import SwiftUI

struct ProfileEditorPreview: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	let draft: ProfileAppearanceDraft
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			profilePicture
		}
		.buttonStyle(.plain)
		.accessibilityLabel("Profile preview")
		.accessibilityHint("Opens profile appearance settings")
		.shadow(radius: 14)
		.animation(
			reduceMotion ? .none : .smooth(duration: 0.35),
			value: draft.contentKind.rawValue
		)
	}

	@ViewBuilder
	private var profilePicture: some View {
		switch draft.contentKind {
			case .photo:
				if let pendingPhotoData = draft.pendingPhotoData,
				   let uiImage = UIImage(data: pendingPhotoData)
				{
					ProfilePicture(
						appearance: draft.appearance,
						localImage: Image(uiImage: uiImage),
						accessibilityName: "Profile preview",
						animatesBackground: true
					)
					.id(ProfileContentKind.photo.rawValue)
					.transition(.blurReplace)
				} else {
					remoteProfilePicture(for: .photo)
				}

			case .monogram:
				remoteProfilePicture(for: .monogram)

			case .emoji:
				remoteProfilePicture(for: .emoji)
		}
	}

	private func remoteProfilePicture(for contentKind: ProfileContentKind) -> some View {
		ProfilePicture(
			appearance: draft.appearance,
			photo: draft.photo,
			accessibilityName: "Profile preview",
			animatesBackground: true
		)
		.id(contentKind.rawValue)
		.transition(.blurReplace)
	}
}
