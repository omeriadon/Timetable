//
//   Bundle.swift
//   Shared
//
//   Created by Adon Omeri on 17/7/2026.
//

import Foundation

enum AppChannel: Equatable {
	case debug
	case testFlight
	case appStore

	static var current: Self {
		#if DEBUG
			return .debug
		#else
			if Bundle.main.appStoreReceiptURL?.path().contains("sandboxReceipt") {
				return .testFlight
			}

			return .appStore
		#endif
	}

	var displayName: String {
		switch self {
			case .debug:
				"Debug"
			case .testFlight:
				"TestFlight"
			case .appStore:
				"App Store"
		}
	}
}

extension Bundle {
	var appVersion: String {
		infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}

	var buildNumber: String {
		infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
	}
}
