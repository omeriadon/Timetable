//
//  TabsView.swift
//  Timetable
//
//  Created by Adon Omeri on 25/7/2026.
//

import SwiftUI

#if os(iOS)
	struct TabsPicker: UIViewRepresentable {
		let items: [(title: String, icon: String)]
		@Binding var selection: Int

		func makeUIView(context _: Context) -> TabsView {
			let view = TabsView()
			view.tintColor = .brown
			view.items = items
			view.onSelectionChange = { selection = $0 }
			view.selectInitialTagIndex(selection)
			return view
		}

		func updateUIView(_ uiView: TabsView, context _: Context) {
			if uiView.selectedTagIndex != selection {
				uiView.selectedTagIndex = selection
			}
		}
	}
#else
	struct TabsPicker: NSViewRepresentable {
		let items: [(title: String, icon: String)]
		@Binding var selection: Int

		func makeNSView(context _: Context) -> TabsView {
			let view = TabsView()
			view.items = items
			view.onSelectionChange = { selection = $0 }
			view.selectInitialTagIndex(selection)
			return view
		}

		func updateNSView(_ nsView: TabsView, context _: Context) {
			if nsView.selectedTagIndex != selection {
				nsView.selectedTagIndex = selection
			}
		}
	}
#endif

#if os(iOS)
	import UIKit

	typealias PlatformView = UIView
	typealias PlatformStackView = UIStackView
	typealias PlatformColor = UIColor
	typealias PlatformFont = UIFont
	typealias PlatformPanGestureRecognizer = UIPanGestureRecognizer
#else
	import AppKit

	typealias PlatformView = NSView
	typealias PlatformStackView = NSStackView
	typealias PlatformColor = NSColor
	typealias PlatformFont = NSFont
	typealias PlatformPanGestureRecognizer = NSPanGestureRecognizer
#endif

class TabsView: PlatformView {
	private var bottomStackView: PlatformStackView!
	private var topStackView: PlatformStackView!
	private var backgroundView: PlatformView!
	private var tagMaskView: PlatformView!
	private var bottomButtons: [PlatformView] = []

	private var isDragging = false
	private var dragStartX: CGFloat = 0

	var onSelectionChange: ((Int) -> Void)?

	var items: [(title: String, icon: String)] = [] {
		didSet { updateButtons(with: items) }
	}

	var selectedTagIndex: Int = 0 {
		didSet { updateSelection(for: selectedTagIndex) }
	}

	func selectInitialTagIndex(_ index: Int) {
		selectedTagIndex = bottomButtons.indices.contains(index) ? index : 0
		setNeedsLayout()
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			updateSelection(for: selectedTagIndex)
		}
	}

	#if os(iOS)
		override init(frame: CGRect) {
			super.init(frame: frame)
			commonInit()
		}
	#else
		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			commonInit()
		}
	#endif

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func commonInit() {
		#if os(macOS)
			wantsLayer = true
		#endif
		setupBottomStackView()
		setupTopStackView()
		setupBackgroundView()
		setupTagMaskView()
		setupPanGesture()
	}

	// MARK: - Stack setup

	private func setupBottomStackView() {
		bottomStackView = PlatformStackView()
		#if os(iOS)
			bottomStackView.axis = .horizontal
		#else
			bottomStackView.orientation = .horizontal
		#endif
		bottomStackView.distribution = .fillEqually
		bottomStackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bottomStackView)
		NSLayoutConstraint.activate([
			bottomStackView.topAnchor.constraint(equalTo: topAnchor),
			bottomStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			bottomStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}

	private func setupTopStackView() {
		topStackView = PlatformStackView()
		#if os(iOS)
			topStackView.axis = .horizontal
			topStackView.isUserInteractionEnabled = false
		#else
			topStackView.orientation = .horizontal
		#endif
		topStackView.distribution = .fillEqually
		topStackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topStackView)
		NSLayoutConstraint.activate([
			topStackView.topAnchor.constraint(equalTo: topAnchor),
			topStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			topStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			topStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}

	// MARK: - Glass background

	private func setupBackgroundView() {
		backgroundView = makeGlassView(tint: .brown)
		#if os(iOS)
			backgroundView.clipsToBounds = true
			backgroundView.isUserInteractionEnabled = false
			insertSubview(backgroundView, aboveSubview: bottomStackView)
		#else
			backgroundView.wantsLayer = true
			backgroundView.layer?.masksToBounds = true
			addSubview(backgroundView, positioned: .above, relativeTo: bottomStackView)
		#endif
	}

	private func makeGlassView(tint: PlatformColor) -> PlatformView {
		#if os(iOS)

			let effect = UIGlassEffect(style: .regular)
			effect.isInteractive = true
			effect.tintColor = tint
			let view = UIVisualEffectView(effect: effect)
			view.layer.cornerCurve = .continuous
			return view

		#else

			let view = NSGlassEffectView()
			view.tintColor = tint
			return view

		#endif
	}

	private func setCornerRadius(_ radius: CGFloat, on view: PlatformView) {
		#if os(iOS)
			view.layer.cornerRadius = radius
		#else
			glass.cornerRadius = radius

		#endif
	}

	private func setupTagMaskView() {
		tagMaskView = PlatformView()
		#if os(iOS)
			tagMaskView.clipsToBounds = true
			tagMaskView.backgroundColor = .black
			tagMaskView.layer.cornerCurve = .continuous
			topStackView.mask = tagMaskView
		#else
			tagMaskView.wantsLayer = true
			tagMaskView.layer?.backgroundColor = PlatformColor.black.cgColor
			tagMaskView.layer?.cornerCurve = .continuous
			topStackView.wantsLayer = true
			topStackView.layer?.mask = tagMaskView.layer
		#endif
	}

	// MARK: - Buttons

	private func updateButtons(with items: [(title: String, icon: String)]) {
		bottomStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		bottomButtons.removeAll()

		for (index, item) in items.enumerated() {
			let bottomButton = button(with: item, foregroundColor: .labelColorCompat, tag: index, interactive: true)
			bottomStackView.addArrangedSubview(bottomButton)
			bottomButtons.append(bottomButton)

			let topButton = button(with: item, foregroundColor: .white, tag: index, interactive: false)
			topStackView.addArrangedSubview(topButton)
		}
	}

	#if os(iOS)
		private func button(with item: (title: String, icon: String), foregroundColor: UIColor, tag: Int, interactive: Bool) -> UIButton {
			let titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { container in
				var container = container
				container.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
				return container
			}
			let button = UIButton(type: .system)
			button.configuration = .plain()
			button.configuration?.title = item.title
			button.configuration?.image = UIImage(systemName: item.icon)
			button.configuration?.imagePadding = 10
			button.configuration?.imagePlacement = .leading
			button.configuration?.cornerStyle = .capsule
			button.configuration?.baseForegroundColor = foregroundColor
			button.configuration?.titleTextAttributesTransformer = titleTextAttributesTransformer
			button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
			button.tag = tag
			button.isUserInteractionEnabled = interactive
			if interactive {
				button.addTarget(self, action: #selector(tagButtonTapped(_:)), for: .touchUpInside)
			}
			return button
		}
	#else
		private func button(with item: (title: String, icon: String), foregroundColor: NSColor, tag: Int, interactive: Bool) -> NSButton {
			let button = NSButton(title: item.title, target: interactive ? self : nil, action: interactive ? #selector(tagButtonTapped(_:)) : nil)
			button.image = NSImage(systemSymbolName: item.icon, accessibilityDescription: item.title)
			button.imagePosition = .imageLeading
			button.imageScaling = .scaleProportionallyDown
			button.bezelStyle = .inline
			button.isBordered = false
			button.tag = tag
			button.attributedTitle = NSAttributedString(
				string: item.title,
				attributes: [
					.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
					.foregroundColor: foregroundColor,
				]
			)
			button.isEnabled = interactive
			return button
		}
	#endif

	@objc private func tagButtonTapped(_ sender: PlatformView) {
		guard let index = bottomButtons.firstIndex(of: sender) else { return }
		animateSelection(to: index)
	}

	// MARK: - Pan gesture

	private func setupPanGesture() {
		let pan = PlatformPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		backgroundView.addGestureRecognizer(pan)
	}

	@objc private func handlePan(_ gesture: PlatformPanGestureRecognizer) {
		guard !bottomButtons.isEmpty else { return }
		let translationX = gesture.translation(in: self).x

		switch gesture.state {
			case .began:
				isDragging = true
				dragStartX = backgroundView.frame.origin.x

			case .changed:
				guard isDragging else { return }
				let width = backgroundView.frame.width
				let minX = bottomButtons.first!.frame.origin.x
				let maxX = bottomButtons.last!.frame.origin.x
				let proposedX = dragStartX + translationX
				let clampedX = min(max(proposedX, minX), maxX)
				moveIndicator(toX: clampedX, width: width)

			case .ended, .cancelled, .failed:
				guard isDragging else { return }
				isDragging = false
				let centerX = backgroundView.frame.midX
				let nearestIndex = nearestButtonIndex(toX: centerX)
				animateSelection(to: nearestIndex)

			default:
				break
		}
	}

	private func moveIndicator(toX x: CGFloat, width: CGFloat) {
		let frame = CGRect(x: x, y: backgroundView.frame.origin.y, width: width, height: backgroundView.frame.height)
		#if os(iOS)
			backgroundView.frame = frame
			tagMaskView.frame = frame
		#else
			CATransaction.begin()
			CATransaction.setDisableActions(true)
			backgroundView.frame = frame
			tagMaskView.frame = frame
			topStackView.layer?.mask?.frame = frame
			CATransaction.commit()
		#endif
	}

	private func nearestButtonIndex(toX x: CGFloat) -> Int {
		var closest = 0
		var closestDistance = CGFloat.greatestFiniteMagnitude
		for (index, button) in bottomButtons.enumerated() {
			let distance = abs(button.frame.midX - x)
			if distance < closestDistance {
				closestDistance = distance
				closest = index
			}
		}
		return closest
	}

	private func animateSelection(to index: Int) {
		#if os(iOS)
			UIView.animate(springDuration: 0.3, bounce: 0.4) {
				self.selectedTagIndex = index
			}
		#else
			NSAnimationContext.runAnimationGroup { context in
				context.duration = 0.3
				context.allowsImplicitAnimation = true
				self.selectedTagIndex = index
			}
		#endif
		onSelectionChange?(index)
	}

	// MARK: - Selection layout

	private func updateSelection(for selectedTagIndex: Int) {
		guard bottomButtons.indices.contains(selectedTagIndex) else { return }
		let frame = bottomButtons[selectedTagIndex].frame
		setCornerRadius(frame.height / 2, on: backgroundView)
		backgroundView.frame = frame
		setCornerRadius(frame.height / 2, on: tagMaskView)
		tagMaskView.frame = frame
		#if os(macOS)
			topStackView.layer?.mask?.frame = frame
		#endif
	}

	#if os(iOS)
		override func layoutSubviews() {
			super.layoutSubviews()
			guard !isDragging else { return }
			UIView.performWithoutAnimation { [unowned self] in
				updateSelection(for: selectedTagIndex)
			}
		}
	#else
		override func layout() {
			super.layout()
			guard !isDragging else { return }
			updateSelection(for: selectedTagIndex)
		}
	#endif
}

#if os(iOS)
	extension UIColor {
		static var labelColorCompat: UIColor {
			.label
		}
	}
#else
	extension NSColor {
		static var labelColorCompat: NSColor {
			.labelColor
		}
	}
#endif
