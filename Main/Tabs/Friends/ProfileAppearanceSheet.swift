import Defaults
import SwiftUI

#if os(iOS)
	import PhotosUI
	import SwiftEmojiIndex
#endif

struct ProfileAppearanceSheet: View {
	let close: () -> Void = {}
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
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
						VStack(alignment: .center, spacing: 10) {
							Text("Background")
								.frame(maxWidth: .infinity, alignment: .leading)
								.foregroundStyle(.secondary)

							VStack(alignment: .leading, spacing: 10) {
								LabeledContent("Animation Speed", value: draft.speed, format: .number.precision(.fractionLength(2)))
								Slider(value: $draft.speed, in: 0 ... 5, step: 0.05)
									.accessibilityLabel("Animation Speed")

								LabeledContent("Texture Noise", value: draft.noise, format: .number.precision(.fractionLength(0)))
								Slider(value: $draft.noise, in: 0 ... 100, step: 1)
									.accessibilityLabel("Texture Noise")
							}

							ProfileColourGrid(selection: $draft.colours)
								.clipShape(ConcentricRectangle(corners: .concentric(minimum: 20), isUniform: false))
						}
						.transition(.blurReplace)
					}
				}
				.animation(.easeInOut, value: draft.contentKind)
				.padding([.horizontal, .top], 10)
				.padding(.bottom, 10)
			}
			.scrollEdgeEffectStyle(.hard, for: .top)
			.scrollEdgeEffectStyle(.hard, for: .bottom)
			.safeAreaBar(edge: .top, alignment: .center, spacing: 12) {
				VStack(spacing: 12) {
					ProfileEditorPreview(draft: draft)
						.frame(width: 250, height: 250)

					HStack {
						Text("Name")
							.foregroundStyle(.tertiary)
							.font(.caption)

						TextField("", text: $draft.displayName)
							.textCase(.uppercase)
							.textFieldStyle(.plain)
							.accessibilityLabel("Profile name")
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
								setContentKind(ProfileContentKind.allCases[$0])
							}
						)
					)
					.frame(height: 40)
				}
				.padding(.horizontal, 10)
				.padding(.top, 10)
				.padding(.bottom, 12)
			}
			.interactiveDismissDisabled()
			.ignoresSafeArea(.all, edges: .bottom)
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
			withAnimation(reduceMotion ? .none : .smooth(duration: 0.35)) {
				draft.pendingPhotoData = nil
				draft.removesPhoto = true
				draft.contentKind = .emoji
			}
			selectedPhotoItem = nil
			photoSelectionState = .idle
			photoCropRequest = nil
		}
	#endif

	private func setContentKind(_ contentKind: ProfileContentKind) {
		withAnimation(reduceMotion ? .none : .smooth(duration: 0.35)) {
			draft.contentKind = contentKind
		}
	}

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
				close()
			} catch {
				statusBadges.present(error: error, title: "Unable to save profile")
			}
		}
	}
}
