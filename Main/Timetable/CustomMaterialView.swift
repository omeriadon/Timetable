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
	func makeNSView(context _: Context) -> NSView {
		let view = NSView()

		let effectView = NSMaterialView(frame: view.bounds)
		effectView.autoresizingMask = [.width, .height]

		let customEffect = NSMaterialView.Effect(
			active: NSMaterialView.Effect.MaterialStyle(
				backgroundColor: NSColor(white: 0.0, alpha: 0.0),
				tintColor: NSColor(white: 0.0, alpha: 0.0),
				tintFilter: kCAFilterLightenBlendMode,
				saturationFactor: 1.0,
				brightnessFactor: 0.0,
				blurRadius: 10
			),
			inactive: NSMaterialView.Effect.MaterialStyle(
				backgroundColor: NSColor(white: 0.0, alpha: 0.0),
				tintColor: NSColor(white: 0.0, alpha: 0.0),
				tintFilter: kCAFilterLightenBlendMode,
				saturationFactor: 1.0,
				brightnessFactor: 0.0,
				blurRadius: 10
			),
			rimColor: (inner: .clear, outer: .clear),
			rimWidth: (inner: 0, outer: 0)
		)

		effectView.effect = customEffect

		view.addSubview(effectView)
		return view
	}

	func updateNSView(_: NSView, context _: Context) {}
}
