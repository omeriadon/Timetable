//
//   Keychain.swift
//   Main
//
//   Created by Adon Omeri on 22/6/2026.
//

import Foundation
import Security

enum KeychainManager {
	private static let service = "com.omeriadon.Timetable"

	@discardableResult
	static func save(data: Data, forKey key: String) -> Bool {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecAttrService as String: service,
		]

		let attributes: [String: Any] = [
			kSecValueData as String: data,
			kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
		]

		let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
		if updateStatus == errSecSuccess {
			return true
		}

		guard updateStatus == errSecItemNotFound else {
			return false
		}

		let item = query.merging(attributes) { _, newValue in newValue }
		return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
	}

	@discardableResult
	static func save(string: String, forKey key: String) -> Bool {
		guard let data = string.data(using: .utf8) else { return false }
		return save(data: data, forKey: key)
	}

	static func readData(forKey key: String) -> Data? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecAttrService as String: service,
			kSecReturnData as String: kCFBooleanTrue as Any,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]

		var dataTypeRef: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

		if status == errSecSuccess {
			return dataTypeRef as? Data
		}

		return nil
	}

	static func read(forKey key: String) -> String? {
		guard let data = readData(forKey: key) else { return nil }
		return String(data: data, encoding: .utf8)
	}

	@discardableResult
	static func delete(forKey key: String) -> Bool {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecAttrService as String: service,
		]

		let status = SecItemDelete(query as CFDictionary)
		return status == errSecSuccess || status == errSecItemNotFound
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
