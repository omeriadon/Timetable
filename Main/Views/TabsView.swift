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
			view.selectedTagIndex = selection
			view.onSelectionChange = { selection = $0 }
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
			view.selectedTagIndex = selection
			view.onSelectionChange = { selection = $0 }
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
#else
	import AppKit

	typealias PlatformView = NSView
	typealias PlatformStackView = NSStackView
	typealias PlatformColor = NSColor
	typealias PlatformFont = NSFont
#endif

class TabsView: PlatformView {
	private var bottomStackView: PlatformStackView!
	private var topStackView: PlatformStackView!
	private var backgroundView: PlatformView!
	private var tagMaskView: PlatformView!

	private var bottomButtons: [PlatformView] = []

	var onSelectionChange: ((Int) -> Void)?

	var items: [(title: String, icon: String)] = [] {
		didSet { updateButtons(with: items) }
	}

	var selectedTagIndex: Int = 0 {
		didSet { updateSelection(for: selectedTagIndex) }
	}

	#if os(iOS)
		override init(frame: CGRect) {
			super.init(frame: frame)
			commonInit()
		}

		@available(*, unavailable)
		required init?(coder _: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	#else
		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			commonInit()
		}

		@available(*, unavailable)
		required init?(coder _: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	#endif

	private func commonInit() {
		#if os(macOS)
			wantsLayer = true
		#endif
		setupBottomStackView()
		setupTopStackView()
		setupBackgroundView()
		setupTagMaskView()
	}

	private func setupBottomStackView() {
		bottomStackView = PlatformStackView()
		bottomStackView.orientation_axis = .horizontal
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
		topStackView.orientation_axis = .horizontal
		topStackView.distribution = .fillEqually
		#if os(iOS)
			topStackView.isUserInteractionEnabled = false
		#endif
		topStackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(topStackView)
		NSLayoutConstraint.activate([
			topStackView.topAnchor.constraint(equalTo: topAnchor),
			topStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			topStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			topStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
		#if os(macOS)
			// NSStackView has no isUserInteractionEnabled; disable hit testing
			// by overriding hitTest on a subclassed view is not available here
			// without a further subclass, so top stack view's buttons are given
			// isEnabled = false instead — see button(with:) below.
		#endif
	}

	private func setupBackgroundView() {
		backgroundView = PlatformView()
		#if os(iOS)
			backgroundView.clipsToBounds = true
			backgroundView.backgroundColor = .tintColor
			backgroundView.layer.cornerCurve = .continuous
			insertSubview(backgroundView, aboveSubview: bottomStackView)
		#else
			backgroundView.wantsLayer = true
			backgroundView.layer?.masksToBounds = true
			backgroundView.layer?.backgroundColor = PlatformColor.controlAccentColor.cgColor
			backgroundView.layer?.cornerCurve = .continuous
			addSubview(backgroundView, positioned: .above, relativeTo: bottomStackView)
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
			button.configuration?.imagePadding = 6
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
			button.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
			button.contentTintColor = foregroundColor
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
		#if os(iOS)
			UIView.animate(springDuration: 0.25, bounce: 0.25) {
				self.selectedTagIndex = index
			}
		#else
			NSAnimationContext.runAnimationGroup { context in
				context.duration = 0.25
				context.allowsImplicitAnimation = true
				self.selectedTagIndex = index
			}
		#endif
		onSelectionChange?(index)
	}

	private func updateSelection(for selectedTagIndex: Int) {
		guard bottomButtons.indices.contains(selectedTagIndex) else { return }
		let button = bottomButtons[selectedTagIndex]
		let frame = button.frame
		#if os(iOS)
			backgroundView.layer.cornerRadius = frame.height / 2
			backgroundView.frame = frame
			tagMaskView.layer.cornerRadius = frame.height / 2
			tagMaskView.frame = frame
		#else
			backgroundView.layer?.cornerRadius = frame.height / 2
			backgroundView.frame = frame
			tagMaskView.layer?.cornerRadius = frame.height / 2
			tagMaskView.frame = frame
			topStackView.layer?.mask?.frame = frame
		#endif
	}

	#if os(iOS)
		override func layoutSubviews() {
			super.layoutSubviews()
			UIView.performWithoutAnimation { [unowned self] in
				updateSelection(for: selectedTagIndex)
			}
		}
	#else
		override func layout() {
			super.layout()
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

	extension NSStackView {
		var orientation_axis: NSUserInterfaceLayoutOrientation {
			get { orientation }
			set { orientation = newValue }
		}
	}

	extension NSView {
		func addSubview(_ view: NSView, positioned: NSWindow.OrderingMode, relativeTo otherView: NSView?) {
			addSubview(view, positioned: positioned, relativeTo: otherView)
		}
	}
#endif

#if os(iOS)
	extension UIStackView {
		var orientation_axis: NSLayoutConstraint.Axis {
			get { axis }
			set { axis = newValue }
		}
	}
#endif
