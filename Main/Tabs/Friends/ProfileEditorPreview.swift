import SwiftUI

struct ProfileEditorPreview: View {
	let draft: ProfileAppearanceDraft

	var body: some View {
		Group {
			#if os(iOS)
				if let pendingPhotoData = draft.pendingPhotoData,
				   let image = UIImage(data: pendingPhotoData)
				{
					Image(uiImage: image)
						.resizable()
						.scaledToFill()
						.clipShape(.circle)
						.accessibilityLabel("Selected profile photo")
				} else {
					profilePicture
				}
			#else
				profilePicture
			#endif
		}
		.shadow(color: .white.opacity(0.3), radius: 14)
	}

	private var profilePicture: some View {
		ProfilePicture(
			appearance: draft.appearance,
			photo: draft.photo,
			accessibilityName: "Profile preview",
			animatesBackground: true
		)
	}
}
