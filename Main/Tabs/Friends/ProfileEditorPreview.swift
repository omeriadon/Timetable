import SwiftUI

struct ProfileEditorPreview: View {
	let draft: ProfileAppearanceDraft

	var body: some View {
		Group {
			#if os(iOS)
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
					profilePicture
				}
			#else
				profilePicture
			#endif
		}
		.shadow(radius: 14)
		.animation(.easeInOut, value: draft.contentKind)
	}

	private var profilePicture: some View {
		ProfilePicture(
			appearance: draft.appearance,
			photo: draft.photo,
			accessibilityName: "Profile preview",
			animatesBackground: true
		)
		.id(draft.contentKind.rawValue)
		.transition(.blurReplace)
	}
}
