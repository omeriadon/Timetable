////
////  BlurView.swift
////  Timetable
////
////  Created by Adon Omeri on 26/7/2026.
////
//
// import QuartzCore
// import SwiftUI
// import UIKit
//
// public struct BlurView: UIViewRepresentable {
//	public var blurRadius: CGFloat = 20
//
//	public init(blurRadius: CGFloat = 20) {
//		self.blurRadius = blurRadius
//	}
//
//	public func makeUIView(context _: Context) -> BlurUIView {
//		BlurUIView(blurRadius: blurRadius)
//	}
//
//	public func updateUIView(_: BlurUIView, context _: Context) {}
// }
//
// open class BlurUIView: UIVisualEffectView {
//	public init(blurRadius: CGFloat = 20) {
//		super.init(effect: UIBlurEffect(style: .regular))
//
//		guard let CAFilter = NSClassFromString("CAFilter")! as? NSObject.Type else {
//			print("[Blur] Error: Can't find CAFilter class")
//			return
//		}
//		guard let blur = CAFilter.perform(NSSelectorFromString("filterWithType:"), with: "gaussianBlur").takeUnretainedValue() as? NSObject else {
//			print("[Blur] Error: CAFilter can't create filterWithType: gaussianBlur")
//			return
//		}
//
//		blur.setValue(blurRadius, forKey: "inputRadius")
//		blur.setValue(true, forKey: "inputNormalizeEdges")
//
//		let backdropLayer = subviews.first?.layer
//		backdropLayer?.filters = [blur]
//
//		for subview in subviews.dropFirst() {
//			subview.alpha = 0
//		}
//	}
//
//	@available(*, unavailable)
//	public required init?(coder _: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//
//	override open func didMoveToWindow() {
//		guard let window, let backdropLayer = subviews.first?.layer else { return }
//		backdropLayer.setValue(window.traitCollection.displayScale, forKey: "scale")
//	}
//
//	override open func traitCollectionDidChange(_: UITraitCollection?) {}
// }
