import Defaults
import SwiftUI

#if os(iOS)
	import PhotosUI
#endif

struct ProfileAppearanceSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var statusBadges
	@State private var service = FriendService.shared
	@State private var draft: ProfileAppearanceDraft
	@State private var isSaving = false
	@State private var presentsEmojiPicker = false
	@State private var presentsFontPicker = false
	@State private var presentsColourPicker = false
	@Namespace private var editorNamespace

	#if os(iOS)
		@State private var selectedPhotoItem: PhotosPickerItem?
		@State private var photoSelectionState = ProfilePhotoSelectionState.idle
		@State private var photoCropRequest: ProfilePhotoCropRequest?
	#endif

	init() {
		_draft = State(initialValue: ProfileAppearanceDraft(
			profile: Defaults[.accountProfile],
			fallbackAppearance: Defaults[.profileAppearance]
		))
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					ProfileEditorPreview(draft: draft)

					TextField("Account name", text: $draft.displayName)
						.textFieldStyle(.roundedBorder)

					ProfileModeControl(
						selection: $draft.contentKind,
						presentsBackground: draft.contentKind != .photo,
						showBackground: showColourPicker
					)

					modeEditor

					if draft.contentKind != .photo {
						Button("Font", systemImage: "textformat", action: showFontPicker)
							.buttonStyle(.glass)
							.matchedTransitionSource(id: "profile-font", in: editorNamespace)

						Button("Background Colours", systemImage: "paintpalette", action: showColourPicker)
							.buttonStyle(.glass)
							.matchedTransitionSource(id: "profile-colours", in: editorNamespace)
					}
				}
				.padding()
			}
			.scrollEdgeEffect()
			.appNavigationTitle("Profile", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel, action: dismiss.callAsFunction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm, action: save)
						.buttonStyle(.glassProminent)
						.disabled(isSaving || !draft.canSave)
				}
			}
		}
		.sheet(isPresented: $presentsEmojiPicker) {
			ProfileEmojiPicker(selection: $draft.emoji)
				.navigationTransition(.zoom(sourceID: "profile-emoji", in: editorNamespace))
				.presentationDetents([.fraction(0.65)])
		}
		.sheet(isPresented: $presentsFontPicker) {
			ProfileFontPicker(
				design: $draft.fontDesign,
				weight: $draft.fontWeight
			)
			.navigationTransition(.zoom(sourceID: "profile-font", in: editorNamespace))
			.presentationDetents([.fraction(0.55)])
		}
		.sheet(isPresented: $presentsColourPicker) {
			ProfileColourGrid(selection: $draft.colours)
				.navigationTransition(.zoom(sourceID: "profile-colours", in: editorNamespace))
				.presentationDetents([.fraction(0.65)])
		}
		#if os(iOS)
			.onChange(of: selectedPhotoItem) { _, item in
				loadPhoto(item)
			}
			.sheet(item: $photoCropRequest) { request in
				ProfilePhotoCropEditor(sourceData: request.sourceData) { preparedData in
					draft.pendingPhotoData = preparedData
					draft.contentKind = .photo
					photoSelectionState = .ready
				}
				.navigationTransition(.zoom(sourceID: "profile-photo-crop", in: editorNamespace))
				.presentationDetents([.fraction(0.7)])
			}
		#endif
	}

	@ViewBuilder
	private var modeEditor: some View {
		switch draft.contentKind {
			case .photo:
				#if os(iOS)
					ProfilePhotoControls(
						selection: $selectedPhotoItem,
						state: photoSelectionState,
						hasCurrentPhoto: draft.photo != nil,
						remove: removePhoto
					)
					.matchedTransitionSource(id: "profile-photo-crop", in: editorNamespace)
				#else
					ContentUnavailableView(
						"Photo Editing Unavailable",
						systemImage: "photo.badge.exclamationmark",
						description: Text("Edit the profile photo on iPhone.")
					)
				#endif
			case .monogram:
				ProfileMonogramEditor(
					monogram: $draft.monogram,
					design: draft.fontDesign,
					weight: draft.fontWeight,
					colours: draft.colours
				)
			case .emoji:
				Button("Choose Emoji", systemImage: "face.smiling", action: showEmojiPicker)
					.buttonStyle(.glass)
					.matchedTransitionSource(id: "profile-emoji", in: editorNamespace)
		}
	}

	private func showEmojiPicker() {
		presentsEmojiPicker = true
	}

	private func showFontPicker() {
		presentsFontPicker = true
	}

	private func showColourPicker() {
		presentsColourPicker = true
	}

	#if os(iOS)
		private func loadPhoto(_ item: PhotosPickerItem?) {
			guard let item else {
				return
			}
			photoSelectionState = .loading
			Task {
				do {
					guard let data = try await item.loadTransferable(type: Data.self) else {
						throw ProfilePhotoSelectionError.unreadableImage
					}
					let preparedSource = try await ProfilePhotoProcessor.prepareSource(data)
					photoCropRequest = ProfilePhotoCropRequest(sourceData: preparedSource)
				} catch {
					photoSelectionState = .failed(error.localizedDescription)
				}
			}
		}

		private func removePhoto() {
			draft.pendingPhotoData = nil
			draft.removesPhoto = true
			draft.contentKind = .emoji
			selectedPhotoItem = nil
			photoSelectionState = .idle
			photoCropRequest = nil
		}
	#endif

	private func save() {
		isSaving = true
		Task {
			defer {
				isSaving = false
			}
			do {
				let profile = try await service.saveProfile(draft)
				draft = ProfileAppearanceDraft(
					profile: profile,
					fallbackAppearance: profile.appearance
				)
				dismiss()
			} catch {
				statusBadges.present(error: error, title: "Unable to save profile")
			}
		}
	}
}
