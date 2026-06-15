//
//  Device.swift
//  Timetable
//
//  Created by Adon Omeri on 13/6/2026.
//

#if canImport(UIKit)
	import UIKit
#endif

enum Device {
	static var isIOS: Bool {
		#if os(iOS)
			return true
		#else
			return false
		#endif
	}

	static var isMacOS: Bool {
		#if os(macOS)
			return true
		#else
			return false
		#endif
	}

	static var isWatchOS: Bool {
		#if os(watchOS)
			return true
		#else
			return false
		#endif
	}

	static var isTVOS: Bool {
		#if os(tvOS)
			return true
		#else
			return false
		#endif
	}

	static var isNotWatchOS: Bool {
		!isWatchOS
	}

	static var isIPad: Bool {
		#if os(iOS)
			return UIDevice.current.userInterfaceIdiom == .pad
		#else
			return false
		#endif
	}

	static var isIPhone: Bool {
		#if os(iOS)
			return UIDevice.current.userInterfaceIdiom == .phone
		#else
			return false
		#endif
	}

	static var isMac: Bool {
		#if os(macOS)
			return true
		#else
			return false
		#endif
	}
}
