//
//  VariableBlurView.swift
//  Timetable
//
//  Created by Adon Omeri on 29/6/2026.
//
#if os(iOS)
	import CoreImage.CIFilterBuiltins
	import QuartzCore
	import SwiftUI
	import UIKit

	public struct VariableBlurView: UIViewRepresentable, Animatable {
		public var topRadius: CGFloat
		public var bottomRadius: CGFloat

		public var animatableData: AnimatablePair<CGFloat, CGFloat> {
			get { AnimatablePair(topRadius, bottomRadius) }
			set {
				topRadius = newValue.first
				bottomRadius = newValue.second
			}
		}

		public init(topRadius: CGFloat = 2, bottomRadius: CGFloat = 10) {
			self.topRadius = topRadius
			self.bottomRadius = bottomRadius
		}

		public func makeUIView(context _: Context) -> VariableBlurUIView {
			VariableBlurUIView(topRadius: topRadius, bottomRadius: bottomRadius)
		}

		public func updateUIView(_ uiView: VariableBlurUIView, context _: Context) {
			uiView.update(topRadius: topRadius, bottomRadius: bottomRadius)
		}
	}

	/// credit https://github.com/jtrivedi/VariableBlurView
	open class VariableBlurUIView: UIVisualEffectView {
		private var variableBlur: NSObject?
		private let ciContext = CIContext()
		private var maskRadii: (top: CGFloat, bottom: CGFloat)?

		public init(topRadius: CGFloat = 0, bottomRadius: CGFloat = 8) {
			super.init(effect: UIBlurEffect(style: .regular))

			guard let CAFilter = NSClassFromString("CAFilter")! as? NSObject.Type else {
				print("[VariableBlur] Error: Can't find CAFilter class")
				return
			}

			guard let variableBlur = CAFilter.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur").takeUnretainedValue() as? NSObject else {
				print("[VariableBlur] Error: CAFilter can't create filterWithType: variableBlur")
				return
			}

			self.variableBlur = variableBlur

			for subview in subviews.dropFirst() {
				subview.alpha = 0
			}

			update(topRadius: topRadius, bottomRadius: bottomRadius)
		}

		@available(*, unavailable)
		public required init?(coder _: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		public func update(topRadius: CGFloat, bottomRadius: CGFloat) {
			let maxRadius = max(topRadius, bottomRadius)

			// Hide the effect once the radius animation reaches zero.
			if maxRadius <= 0 {
				isHidden = true
				return
			} else {
				isHidden = false
			}

			let normalizedRadii = (
				top: topRadius / maxRadius,
				bottom: bottomRadius / maxRadius
			)

			if maskRadii?.top != normalizedRadii.top || maskRadii?.bottom != normalizedRadii.bottom,
			   let gradientImage = makeGradientImage(
			   	topRadius: normalizedRadii.top,
			   	bottomRadius: normalizedRadii.bottom
			   )
			{
				variableBlur?.setValue(gradientImage, forKey: "inputMaskImage")
				maskRadii = normalizedRadii
			}

			variableBlur?.setValue(maxRadius, forKey: "inputRadius")
			variableBlur?.setValue(true, forKey: "inputNormalizeEdges")

			if let backdropLayer = subviews.first?.layer, let blur = variableBlur {
				backdropLayer.filters = [blur]
			}
		}

		override open func didMoveToWindow() {
			guard let window, let backdropLayer = subviews.first?.layer else { return }
			backdropLayer.setValue(window.traitCollection.displayScale, forKey: "scale")
		}

		override open func traitCollectionDidChange(_: UITraitCollection?) {}

		private func makeGradientImage(width: CGFloat = 100, height: CGFloat = 100, topRadius: CGFloat, bottomRadius: CGFloat) -> CGImage? {
			let ciGradientFilter = CIFilter.linearGradient()

			let maxRadius = max(topRadius, bottomRadius)
			let minRadius = min(topRadius, bottomRadius)

			// Handle uniform blur edge-case safely if values match
			if maxRadius == minRadius {
				ciGradientFilter.color0 = CIColor.black
				ciGradientFilter.color1 = CIColor.black
				ciGradientFilter.point0 = CGPoint(x: 0, y: 0)
				ciGradientFilter.point1 = CGPoint(x: 0, y: height)
			} else {
				// Keep the original system colors intact to prevent rendering failures
				ciGradientFilter.color0 = CIColor.black // Alpha 1.0
				ciGradientFilter.color1 = CIColor.clear // Alpha 0.0

				let ratio = minRadius / maxRadius // 2 / 10 = 0.2

				if bottomRadius > topRadius {
					// Bottom is 10px (Alpha 1.0), Top is 2px (Alpha 0.2)
					ciGradientFilter.point0 = CGPoint(x: 0, y: 0)
					let targetY = height / (1.0 - ratio) // Shifts point1 beyond bounds to clamp alpha to 0.2 at the top
					ciGradientFilter.point1 = CGPoint(x: 0, y: targetY)
				} else {
					// Top is 10px (Alpha 1.0), Bottom is 2px (Alpha 0.2)
					ciGradientFilter.point0 = CGPoint(x: 0, y: height)
					let targetY = height - (height / (1.0 - ratio))
					ciGradientFilter.point1 = CGPoint(x: 0, y: targetY)
				}
			}

			guard let outputImage = ciGradientFilter.outputImage,
			      let cgImage = ciContext.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: width, height: height))
			else {
				return nil
			}

			return cgImage
		}
	}
#endif
