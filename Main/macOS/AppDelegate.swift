//
//  AppDelegate.swift
//  Timetable
//
//  Created by Adon Omeri on 15/6/2026.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_: Notification) {
		guard let window = NSApplication.shared.windows.first else { return }

		window.isOpaque = false
		window.backgroundColor = .clear

		window.titlebarAppearsTransparent = true
	}
}
