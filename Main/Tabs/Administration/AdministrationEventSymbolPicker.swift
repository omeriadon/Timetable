import SFSymbolsPicker
import SwiftUI

struct AdministrationEventSymbolPicker: View {
	@Binding var symbol: String

	var body: some View {
		SymbolsPicker(
			selection: $symbol,
			title: "",
			searchLabel: "Search symbols...",
			autoDismiss: true
		)
	}
}
