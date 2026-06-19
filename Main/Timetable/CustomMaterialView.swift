//
//  CustomMaterialView.swift
//  Timetable
//
//  Created by Adon Omeri on 15/6/2026.
//

import AppKit
import MaterialView
import SwiftUI

struct CustomMaterialView: NSViewRepresentable {
	@Environment(\.colorScheme) private var colorScheme

	final class Container: NSView {
		let effectView = NSMaterialView()

		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			addSubview(effectView)
			effectView.autoresizingMask = [.width, .height]
			effectView.frame = bounds
		}

		required init?(coder: NSCoder) {
			super.init(coder: coder)
		}
	}

	func makeNSView(context: Context) -> Container {
		let view = Container()

		view.effectView.effect = makeEffect(for: context.environment.colorScheme)

		return view
	}

	func updateNSView(_ nsView: Container, context: Context) {
		nsView.effectView.effect = makeEffect(for: context.environment.colorScheme)
	}

	private func makeEffect(for scheme: ColorScheme) -> NSMaterialView.Effect {
		let isDark = scheme == .dark

		return NSMaterialView.Effect(
			active: NSMaterialView.Effect.MaterialStyle(
				backgroundColor: isDark ? NSColor.clear : NSColor.white.withAlphaComponent(0.3),
				tintColor: NSColor(white: 0.0, alpha: 0.0),
				tintFilter: kCAFilterLightenBlendMode,
				saturationFactor: 1.0,
				brightnessFactor: 0.0,
				blurRadius: 8
			),
			inactive: NSMaterialView.Effect.MaterialStyle(
				backgroundColor: isDark ? NSColor.black.withAlphaComponent(0.2) : NSColor.white.withAlphaComponent(0.5),
				tintColor: NSColor(white: 0.0, alpha: 0.0),
				tintFilter: kCAFilterDarkenBlendMode,
				saturationFactor: 1.0,
				brightnessFactor: 0.0,
				blurRadius: 8
			),
			rimColor: (inner: .clear, outer: .clear),
			rimWidth: (inner: 0, outer: 0)
		)
	}
}
