import SwiftUI

#if os(iOS)
	import SFSymbolsPicker
#endif

struct AdministrationEventSymbolPicker: View {
	@Binding var symbol: String

	var body: some View {
		#if os(iOS)
			SymbolsPicker(
				selection: $symbol,
				title: "",
				searchLabel: "Search symbols...",
				autoDismiss: true
			)
		#else
			Form {
				TextField("SF Symbol Name", text: $symbol)
				Label("Preview", systemImage: symbol)
			}
			.padding()
		#endif
	}
}
