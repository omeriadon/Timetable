//
//  Keychain.swift
//  Timetable
//
//  Created by Adon Omeri on 22/6/2026.
//

import Foundation
import Security

enum KeychainManager {
	static func save(string: String, forKey key: String) {
		guard let data = string.data(using: .utf8) else { return }

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecValueData as String: data,
		]

		// Always delete the old item first to ensure a clean overwrite
		SecItemDelete(query as CFDictionary)
		SecItemAdd(query as CFDictionary, nil)
	}

	static func read(forKey key: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: kCFBooleanTrue!,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]

		var dataTypeRef: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

		if status == errSecSuccess, let data = dataTypeRef as? Data, let string = String(data: data, encoding: .utf8) {
			return string
		}
		return nil
	}
}

class DeviceIDProvider {
	static let shared = DeviceIDProvider()
	private let keychainKey = "com.omeriadon.Timetable.uniqueDeviceID"

	/// Fetches the persistent device ID from the Keychain, creating it if it doesn't exist.
	func getDeviceID() -> String {
		if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
			return "1"
		}

		// Look for an existing ID
		if let existingID = KeychainManager.read(forKey: keychainKey) {
			return existingID
		}

		// Generate a fresh UUID if one wasn't found
		let newID = UUID().uuidString
		KeychainManager.save(string: newID, forKey: keychainKey)
		return newID
	}
}
