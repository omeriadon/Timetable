//
//   CustomMaterialView.swift
//   Main
//
//   Created by Adon Omeri on 16/6/2026.
//

import AppKit
import SwiftUI

struct CustomMaterialView: NSViewRepresentable {
	@Environment(\.colorScheme) private var colorScheme

	final class Container: NSView {
		let effectView = NSVisualEffectView()
		let tintView = NSView()

		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			addSubview(effectView)
			addSubview(tintView)
			effectView.autoresizingMask = [.width, .height]
			effectView.frame = bounds
			tintView.autoresizingMask = [.width, .height]
			tintView.frame = bounds
			tintView.wantsLayer = true
		}

		required init?(coder: NSCoder) {
			super.init(coder: coder)
		}
	}

	func makeNSView(context: Context) -> Container {
		let view = Container()

		configure(view, for: context.environment.colorScheme)

		return view
	}

	func updateNSView(_ nsView: Container, context: Context) {
		configure(nsView, for: context.environment.colorScheme)
	}

	private func configure(_ view: Container, for scheme: ColorScheme) {
		let isDark = scheme == .dark
		view.effectView.material = .underWindowBackground
		view.effectView.blendingMode = .behindWindow
		view.effectView.state = .active
		view.effectView.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
		view.tintView.layer?.backgroundColor = (isDark ? NSColor.black : NSColor.white)
			.withAlphaComponent(isDark ? 0.025 : 0.02)
			.cgColor
	}
}
