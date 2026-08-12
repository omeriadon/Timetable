import Defaults
import DialStylePicker
import PhotosUI
import SwiftEmojiIndex
import SwiftUI

struct ProfileAppearanceSheet: View {
	let close: () -> Void
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@Environment(\.statusBadgeManager) private var statusBadges
	@State private var service = FriendService.shared
	@State private var draft: ProfileAppearanceDraft
	@State private var isSaving = false
	@State private var presentsEmojiPicker = false

	@State private var selectedPhotoItem: PhotosPickerItem?
	@State private var photoSelectionState = ProfilePhotoSelectionState.idle
	@State private var photoCropRequest: ProfilePhotoCropRequest?

	init(close: @escaping () -> Void) {
		self.close = close
		_draft = State(initialValue: ProfileAppearanceDraft(
			profile: Defaults[.accountProfile],
			fallbackAppearance: Defaults[.profileAppearance]
		))
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					if draft.contentKind == .photo {
						ProfilePhotoControls(
							selection: $selectedPhotoItem,
							state: photoSelectionState,
							hasCurrentPhoto: draft.photo != nil,
							remove: removePhoto
						)
						.transition(.blurReplace)

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
						.transition(.blurReplace)
						.buttonSizing(.flexible)
					}

					if draft.contentKind != .photo {
						ProfileForegroundEditor(
							contentKind: draft.contentKind,
							foregroundColour: $draft.foregroundColour,
							fontDesign: $draft.fontDesign,
							fontWeight: $draft.fontWeight,
							monogram: $draft.monogram
						)

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
					ProfileEditorPreview(draft: draft, onTap: reopenPhotoCrop)
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

					DialStylePicker(selection: $draft.contentKind) {
						Label("Photo", systemImage: "photo")
							.tag(ProfileContentKind.photo)
							.dialStylePickerGroup("profile-content")

						Label("Monogram", systemImage: "character")
							.tag(ProfileContentKind.monogram)
							.dialStylePickerGroup("profile-content")

						Label("Emoji", systemImage: "face.smiling")
							.tag(ProfileContentKind.emoji)
							.dialStylePickerGroup("profile-content")
					}
					.tint(.brown)
					.frame(height: 40)
				}
				.padding(.horizontal, 10)
				.padding(.top, 10)
				.padding(.bottom, 12)
			}
			.ignoresSafeArea(.all, edges: .bottom)
			.appNavigationTitle("Profile", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", role: .cancel, action: close)
						.labelStyle(.iconOnly)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm, action: save)
						.buttonStyle(.glassProminent)
						.labelStyle(.iconOnly)
						.disabled(isSaving || !draft.canSave)
				}
			}
		}
		.foregroundStyle(Color.primary)
		.sheet(isPresented: $presentsEmojiPicker) {
			ProfileEmojiPicker(
				selection: $draft.emoji,
				close: { presentsEmojiPicker = false }
			)
			.presentationDetents([.large])
			.appPaperPresentation()
		}

		.onChange(of: selectedPhotoItem) { _, item in
			loadPhoto(item)
		}
		.sheet(item: $photoCropRequest) { request in
			ProfilePhotoCropEditor(
				sourceData: request.sourceData,
				completion: { preparedData in
					draft.pendingPhotoData = preparedData
					draft.contentKind = .photo
					photoSelectionState = .ready
				},
				close: { photoCropRequest = nil }
			)
			.presentationDetents([.fraction(0.7)])
			.appPaperPresentation()
		}
	}

	private func showEmojiPicker() {
		presentsEmojiPicker = true
	}

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

	private func reopenPhotoCrop() {
		if let pendingPhotoData = draft.pendingPhotoData {
			photoCropRequest = ProfilePhotoCropRequest(sourceData: pendingPhotoData)
			return
		}

		guard let photo = draft.photo else { return }
		Task {
			guard let data = await ProfileImageCache.shared.imageData(for: photo, displaySize: 300) else {
				return
			}
			photoCropRequest = ProfilePhotoCropRequest(sourceData: data)
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

private struct ProfileForegroundEditor: View {
	let contentKind: ProfileContentKind
	@Binding var foregroundColour: RGBAColor
	@Binding var fontDesign: ProfileFontDesign
	@Binding var fontWeight: ProfileFontWeight
	@Binding var monogram: String
	@State private var presentsFontPicker = false

	var body: some View {
		VStack(alignment: .center, spacing: 10) {
			Text("Foreground")
				.frame(maxWidth: .infinity, alignment: .leading)
				.foregroundStyle(.secondary)

			ProfileForegroundColourGrid(selection: $foregroundColour)
				.clipShape(ConcentricRectangle(corners: .concentric(minimum: 12), isUniform: false))

			if contentKind == .monogram {
				GlassEffectContainer(spacing: 5) {
					HStack {
						Button("Font", systemImage: "textformat") {
							presentsFontPicker = true
						}
						.buttonStyle(.glass)
						.popover(isPresented: $presentsFontPicker) {
							ProfileFontPicker(
								design: $fontDesign,
								weight: $fontWeight
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

							TextField("", text: $monogram)
								.textCase(.uppercase)
								.textFieldStyle(.plain)
								.accessibilityLabel("Profile monogram")
								.onChange(of: monogram) { _, value in
									let normalized = String(value.prefix(3)).uppercased()
									if normalized != value {
										monogram = normalized
									}
								}
						}
						.padding(5)
						.padding(.horizontal, 5)
						.glassEffect(.clear.interactive())
					}
				}
			}
		}
	}
}
