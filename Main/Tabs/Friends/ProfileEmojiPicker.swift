import SwiftEmoji
import SwiftUI

struct ProfileEmojiPicker: View {
	let close: () -> Void = {}

	@State private var searchText = ""
	@State private var sections: [EmojiSection] = []
	@Binding private var selected: Emoji?
	@State private var searchResults: [Emoji] = []

	init(selection: Binding<String>) {
		_selected = Binding(
			get: {
				Emoji(selection.wrappedValue)
			},
			set: { emoji in
				guard let emoji else { return }
				selection.wrappedValue = emoji.character
			}
		)
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				ZStack {
					if searchText.isEmpty {
						EmojiGrid(sections: sections, selection: $selected)
							.transition(.blurReplace)
					} else {
						EmojiGrid(emojis: searchResults, selection: $selected)
							.transition(.blurReplace)
					}
				}
				.padding(.horizontal)
				.animation(.easeInOut, value: searchText.isEmpty)
			}
			.searchable(text: $searchText, prompt: "Search emoji")
			.appNavigationTitle("Emoji", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel, action: dismiss.callAsFunction)
				}
			}
		}
		.onChange(of: searchText) { _, query in
			Task {
				searchResults = query.isEmpty ? [] :
					await EmojiIndexProvider.shared.search(query, ranking: .usage)
			}
		}
		.onChange(of: selected) { _, newValue in
			guard newValue != nil else { return }
			close()
		}
		.task {
			sections = await (try? EmojiIndexProvider.shared.sections) ?? []
		}
	}
}
