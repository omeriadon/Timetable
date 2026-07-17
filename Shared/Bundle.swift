//
//   Bundle.swift
//   Shared
//
//   Created by Adon Omeri on 17/7/2026.
//

import Foundation

extension Bundle {
	var appVersion: String {
		infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}

	var buildNumber: String {
		infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
	}
}
