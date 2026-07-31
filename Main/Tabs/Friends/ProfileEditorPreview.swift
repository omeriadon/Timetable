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
						.frame(width: 200, height: 200)
						.clipShape(.circle)
						.accessibilityLabel("Selected profile photo")
				} else {
					profilePicture
				}
			#else
				profilePicture
			#endif
		}
		.shadow(radius: 12)
	}

	private var profilePicture: some View {
		ProfilePicture(
			appearance: draft.appearance,
			photo: draft.photo,
			size: 200,
			accessibilityName: "Profile preview",
			animatesBackground: true
		)
	}
}
