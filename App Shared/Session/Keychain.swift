//
//   Keychain.swift
//   App Shared
//
//   Created by Adon Omeri on 22/6/2026.
//

import Foundation
import Security

enum KeychainManager {
	private static let service = "com.omeriadon.Timetable"
	private static let sharedAccessGroup = "P6PV2R9443.com.omeriadon.Timetable.keychain.shared"

	@discardableResult
	static func save(data: Data, forKey key: String) -> Bool {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecAttrService as String: service,
			kSecAttrAccessGroup as String: sharedAccessGroup,
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
		if let data = readData(forKey: key, accessGroup: sharedAccessGroup) {
			return data
		}
		guard let legacyData = readData(forKey: key, accessGroup: nil) else { return nil }
		_ = save(data: legacyData, forKey: key)
		return legacyData
	}

	private static func readData(forKey key: String, accessGroup: String?) -> Data? {
		var query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecAttrService as String: service,
			kSecReturnData as String: kCFBooleanTrue as Any,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]
		if let accessGroup {
			query[kSecAttrAccessGroup as String] = accessGroup
		}

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
		let sharedQuery: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecAttrService as String: service,
			kSecAttrAccessGroup as String: sharedAccessGroup,
		]

		let sharedStatus = SecItemDelete(sharedQuery as CFDictionary)
		var legacyQuery = sharedQuery
		legacyQuery.removeValue(forKey: kSecAttrAccessGroup as String)
		let legacyStatus = SecItemDelete(legacyQuery as CFDictionary)
		return [sharedStatus, legacyStatus].allSatisfy { $0 == errSecSuccess || $0 == errSecItemNotFound }
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
