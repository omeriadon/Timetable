import Defaults
import SwiftUI

#if os(iOS)
	import PhotosUI
	import SwiftEmojiIndex
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
			VStack(spacing: 20) {
				ProfileEditorPreview(draft: draft)
					.padding(.horizontal)
					.frame(maxHeight: .infinity)

				HStack {
					Text("Name")
						.foregroundStyle(.tertiary)
						.font(.caption)

					TextField("", text: $draft.displayName)
						.textCase(.uppercase)
						.textFieldStyle(.plain)
						.accessibilityLabel("Profile monogram")
						.onChange(of: draft.monogram) { _, value in
							let normalized = String(value.prefix(3)).uppercased()
							if normalized != value {
								draft.monogram = normalized
							}
						}
				}
				.padding(5)
				.padding(.horizontal, 5)
				.glassEffect(.regular.interactive())

				TabsPicker(
					items: [
						("Photo", "photo"),
						("Monogram", "character"),
						("Emoji", "face.smiling"),
					],
					selection: Binding(
						get: {
							ProfileContentKind.allCases.firstIndex(of: draft.contentKind)!
						},
						set: {
							draft.contentKind = ProfileContentKind.allCases[$0]
						}
					)
				)
				.frame(height: 40)

				if draft.contentKind == .monogram {
					GlassEffectContainer(spacing: 5) {
						HStack {
							Button(action: showFontPicker) {
								Label {
									Text("Font")
								} icon: {
									Image(systemName: "textformat")
										.foregroundStyle(.tertiary)
										.font(.caption)
								}
							}
							.buttonStyle(.glass)
							.popover(isPresented: $presentsFontPicker) {
								ProfileFontPicker(
									design: $draft.fontDesign,
									weight: $draft.fontWeight
								)
								.frame(width: 300, height: 400)
								.presentationCompactAdaptation(.popover)
							}

							Spacer()
								.frame(width: 15)

							HStack {
								Text("Monogram")
									.foregroundStyle(.tertiary)
									.font(.caption)

								TextField("", text: $draft.monogram)
									.textCase(.uppercase)
									.textFieldStyle(.plain)
									.accessibilityLabel("Profile monogram")
									.onChange(of: draft.monogram) { _, value in
										let normalized = String(value.prefix(3)).uppercased()
										if normalized != value {
											draft.monogram = normalized
										}
									}
							}
							.padding(5)
							.padding(.horizontal, 5)
							.glassEffect(.clear.interactive())
						}
					}
					.transition(.blurReplace)
				}

				if draft.contentKind == .photo {
					#if os(iOS)
						ProfilePhotoControls(
							selection: $selectedPhotoItem,
							state: photoSelectionState,
							hasCurrentPhoto: draft.photo != nil,
							remove: removePhoto
						)
						.matchedTransitionSource(id: "profile-photo-crop", in: editorNamespace)
						.transition(.blurReplace)
					#else
						ContentUnavailableView(
							"Photo Editing Unavailable",
							systemImage: "photo.badge.exclamationmark",
							description: Text("Edit the profile photo on iPhone.")
						)
						.transition(.blurReplace)
					#endif
				} else if draft.contentKind == .emoji {
					Button(action: showEmojiPicker) {
						Label {
							Text("Choose Emoji")
						} icon: {
							Image(systemName: "face.smiling")
								.foregroundStyle(.tertiary)
								.font(.caption)
						}
					}
					.buttonStyle(.glass)
					.matchedTransitionSource(id: "profile-emoji", in: editorNamespace)
					.transition(.blurReplace)
					.buttonSizing(.flexible)
				}

				if draft.contentKind != .photo {
					VStack(alignment: .leading) {
						Text("Background")
							.frame(maxWidth: .infinity, alignment: .leading)
							.foregroundStyle(.secondary)
						ProfileColourGrid(selection: $draft.colours)
							.clipShape(ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: true))
					}
					.ignoresSafeArea(.all, edges: .bottom)
					.transition(.blurReplace)
				}
			}
			.animation(.easeInOut, value: draft.contentKind)
			.padding([.horizontal, .top], 10)
			.padding(.bottom, 10)
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
				.presentationDetents([.large])
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
