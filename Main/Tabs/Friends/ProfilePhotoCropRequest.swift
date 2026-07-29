#if os(iOS)
	import Foundation

	struct ProfilePhotoCropRequest: Identifiable {
		let id = UUID()
		let sourceData: Data
	}
#endif
