//
//  StatusBadgeOverlayWindow.swift
//  Timetable
//

import AppKit
import SwiftUI

@MainActor
final class StatusBadgeOverlayWindowController {
	static let shared = StatusBadgeOverlayWindowController()

	private let manager = StatusBadgeManager.shared
	private var panel: StatusBadgeOverlayPanel?
	private var observationTask: Task<Void, Never>?
	private var notificationTokens: [NSObjectProtocol] = []

	private init() {}

	func start() {
		guard panel == nil else {
			refresh()
			return
		}

		let panel = StatusBadgeOverlayPanel()
		panel.contentView = NSHostingView(
			rootView: StatusBadgeOverlay()
				.environment(\.statusBadgeManager, manager)
				.padding(8)
		)
		self.panel = panel

		let notificationCenter = NotificationCenter.default
		let controller = self
		for name in [
			NSWindow.didBecomeKeyNotification,
			NSWindow.didBecomeMainNotification,
			NSWindow.didMoveNotification,
			NSWindow.didResizeNotification,
			NSWindow.didEndSheetNotification,
			NSApplication.didBecomeActiveNotification,
			NSApplication.didResignActiveNotification,
		] {
			let token = notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak controller] _ in
				Task { @MainActor [weak controller] in controller?.refresh() }
			}
			notificationTokens.append(token)
		}

		observeBadgeChanges()
		refresh()
	}

	isolated deinit {
		observationTask?.cancel()

		for token in notificationTokens {
			NotificationCenter.default.removeObserver(token)
		}

		panel?.orderOut(nil)
	}

	private func observeBadgeChanges() {
		observationTask?.cancel()
		observationTask = Task { @MainActor [weak self] in
			guard let self else { return }
			withObservationTracking {
				_ = self.manager.mainBadge
				_ = self.manager.badges
			} onChange: {
				let controller = self
				Task { @MainActor [weak controller] in
					guard let controller, !Task.isCancelled else { return }
					controller.refresh()
					controller.observeBadgeChanges()
				}
			}
		}
	}

	private func refresh() {
		guard let panel else { return }
		guard NSApp.isActive, manager.mainBadge != nil, let hostWindow else {
			panel.orderOut(nil)
			return
		}

		let size = NSSize(width: 266, height: 96)
		panel.setContentSize(size)
		let hostFrame = hostWindow.convertToScreen(hostWindow.contentView?.bounds ?? .zero)
		let origin = NSPoint(
			x: hostFrame.midX - size.width / 2,
			y: hostFrame.maxY - size.height - 18
		)
		panel.setFrame(NSRect(origin: origin, size: size), display: true)
		panel.orderFront(nil)
	}

	private var hostWindow: NSWindow? {
		let candidate = NSApp.keyWindow ?? NSApp.mainWindow
		return candidate === panel ? nil : candidate
	}
}

private final class StatusBadgeOverlayPanel: NSPanel {
	init() {
		super.init(
			contentRect: NSRect(x: 0, y: 0, width: 266, height: 96),
			styleMask: [.borderless, .nonactivatingPanel],
			backing: .buffered,
			defer: true
		)

		isOpaque = false
		backgroundColor = .clear
		hasShadow = false
		level = .modalPanel
		worksWhenModal = true
		hidesOnDeactivate = false
		isReleasedWhenClosed = false
		collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
		isMovableByWindowBackground = false
	}

	override var canBecomeKey: Bool {
		false
	}

	override var canBecomeMain: Bool {
		false
	}
}
