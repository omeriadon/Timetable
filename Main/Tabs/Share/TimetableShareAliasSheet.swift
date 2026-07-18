import ColorfulX
import Defaults
#if canImport(FocusOnAppear)
	import FocusOnAppear
#endif
import SwiftUI

struct TimetableShareAliasSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@FocusState private var isFocused: Bool
	@State private var service = TimetableShareAliasService.shared
	@State private var rawInput = ""
	@State private var editRevision = 0
	@State private var colors = [Color.clear, .clear, .clear, .clear, .clear, .mint]

	var body: some View {
		ZStack {
			ColorfulView(color: $colors, speed: .constant(reduceMotion ? 0 : 0.25), bias: .constant(0.00001), noise: .constant(64), transitionSpeed: .constant(10), frameLimit: .constant(60), renderScale: .constant(1))
				.opacity(0.8)
				.allowsHitTesting(false)
				.ignoresSafeArea()
			VStack(alignment: .leading, spacing: 18) {
				HStack { Spacer(); Button("Close", role: .cancel) { dismiss() }.frame(minWidth: 44, minHeight: 44) }
				Text("Choose your link").font(.largeTitle.bold())
				Text("Create a short, memorable link for your timetable.").foregroundStyle(.secondary)
				Text("timetable.adonis.pt/sharedtimetable/").font(.caption.monospaced()).foregroundStyle(.secondary)
				ZStack(alignment: .leading) {
					TextField("your link", text: $rawInput)
					#if !os(macOS)
						.textInputAutocapitalization(.never)
						.keyboardType(.asciiCapable)
					#endif
						.autocorrectionDisabled(true)
						.submitLabel(.done)
						.focused($isFocused)
					#if canImport(FocusOnAppear)
						.focusOnAppear()
					#endif
						.foregroundStyle(.clear)
						.tint(.mint)
						.accessibilityLabel("Custom timetable link")
					Text(rawInput.isEmpty ? "your-link" : rawInput)
						.foregroundStyle(service.validation == nil ? Color.primary : Color.red)
						.font(.title3.monospaced())
						.contentTransition(.numericText(value: Double(editRevision)))
				}
				.padding(14)
				.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
				.onTapGesture { isFocused = true }
				Text(statusText)
					.font(.callout)
					.foregroundStyle(service.availability?.isAvailable == true ? .mint : .red)
					.frame(minHeight: 24, alignment: .leading)
				HStack {
					Text("\(rawInput.count)/30").font(.caption.monospaced()).contentTransition(.numericText(value: Double(rawInput.count)))
					Spacer()
					Button("Save") { Task {
						if await service.save() {
							dismiss()
						}
					} }
					.buttonStyle(.borderedProminent)
					.disabled(service.validation != nil || service.availability?.isAvailable != true || service.isSaving)
				}
				if !service.currentAlias.isEmpty {
					Button("Remove Custom Link", role: .destructive) { Task {
						if await service.remove() {
							dismiss()
						}
					} }
				}
				Spacer()
			}
			.padding(24)
		}
		.interactiveDismissDisabled(true)
		.scrollDismissesKeyboard(.never)
		.task {
			await service.fetchCurrentAlias()
			rawInput = service.currentAlias
			service.updateCandidate(rawInput)
			isFocused = true
		}
		.onChange(of: rawInput) { _, value in editRevision += 1; service.updateCandidate(value) }
	}

	private var statusText: String {
		if rawInput.isEmpty {
			return "Choose at least 3 characters."
		}
		if let error = service.validation {
			switch error.reason {
				case .tooShort: return "Use at least 3 characters."
				case .tooLong: return "Use at most 30 characters."
				case .invalidCharacter: return "Links can contain letters, numbers, - and _."
				case .leadingSeparator, .trailingSeparator: return "Start and end with a letter or number."
				case .consecutiveSeparators: return "Do not use separators together."
				case .reserved: return "That link is reserved."
				case .uuidShaped: return "Choose a custom link instead of a UUID."
				case .empty: return "Choose at least 3 characters."
			}
		}
		if service.availability?.reason == .taken {
			return "That link is already taken."
		}
		if service.availability?.isOwnedByCurrentUser == true {
			return "This is already your link."
		}
		if service.availability?.isAvailable == true {
			return "This link is available."
		}
		return "Checking availability…"
	}
}
