import SwiftUI

struct ProfileEmojiPicker: View {
	@Environment(\.dismiss) private var dismiss
	@Binding var selection: String
	@State private var searchText = ""

	private let emojis = [
		"😀", "😃", "😄", "😁", "😆", "🥹", "😊", "🙂", "🙃", "😉",
		"😍", "🥰", "😘", "😎", "🤓", "🧐", "🥳", "🤩", "🫡", "🤠",
		"🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
		"🦁", "🐮", "🐷", "🐸", "🐵", "🦄", "🐝", "🦋", "🐙", "🦖",
		"🍎", "🍊", "🍋", "🍉", "🍇", "🍓", "🍒", "🥝", "🍕", "🍔",
		"⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸",
		"🎨", "🎭", "🎮", "🎸", "🎹", "🎺", "🎻", "🥁", "📚", "✏️",
		"⭐️", "🌟", "✨", "⚡️", "🔥", "🌈", "☀️", "🌙", "🌊", "🍀",
		"❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💖",
		"🚗", "🚌", "🚲", "✈️", "🚀", "🛸", "⛵️", "🚂", "🚁", "🏎️",
	]

	var body: some View {
		NavigationStack {
			ScrollView {
				LazyVGrid(
					columns: [GridItem(.adaptive(minimum: 48), spacing: 8)],
					spacing: 8
				) {
					ForEach(filteredEmojis, id: \.self) { emoji in
						Button("Choose \(emoji)") {
							selection = emoji
							dismiss()
						} label: {
							Label {
								Text(emoji)
									.font(.title)
							} icon: {
								Image(systemName: "face.smiling")
									.hidden()
									.frame(width: 0)
							}
							.frame(minWidth: 44, minHeight: 44)
							.background(
								selection == emoji ? Color.accentColor.opacity(0.18) : .clear,
								in: .circle
							)
						}
						.buttonStyle(.plain)
					}
				}
				.padding()
			}
			.searchable(text: $searchText, prompt: "Search emoji")
			.appNavigationTitle("Emoji", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel, action: dismiss.callAsFunction)
				}
			}
		}
	}

	private var filteredEmojis: [String] {
		guard !searchText.isEmpty else {
			return emojis
		}
		return emojis.filter {
			$0.localizedStandardContains(searchText)
				|| emojiSearchName($0).localizedStandardContains(searchText)
		}
	}

	private func emojiSearchName(_ emoji: String) -> String {
		switch emoji {
			case "📚":
				"books school study"
			case "✏️":
				"pencil school write"
			case "⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸":
				"sport ball game"
			case "🎨", "🎭", "🎮", "🎸", "🎹", "🎺", "🎻", "🥁":
				"art music game hobby"
			case "⭐️", "🌟", "✨":
				"star sparkle"
			case "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💖":
				"heart love"
			default:
				emoji
		}
	}
}
