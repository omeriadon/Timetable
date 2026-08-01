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
			ContentUnavailableView(
				"Symbol Picker Unavailable",
				systemImage: symbol,
				description: Text("SF Symbols can be selected on iPhone and iPad.")
			)
		#endif
	}
}
