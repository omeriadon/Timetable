#if os(macOS)
	import AppKit
	import SwiftUI

	struct CustomMaterialView: NSViewRepresentable {
		func makeNSView(context _: Context) -> NSVisualEffectView {
			let view = NSVisualEffectView()
			view.material = .popover
			view.blendingMode = .behindWindow
			view.state = .active
			return view
		}

		func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
			nsView.material = .popover
			nsView.blendingMode = .behindWindow
			nsView.state = .active
		}
	}
#endif
