//
//  generatePass.swift
//  Timetable
//
//  Created by Adon Omeri on 21/6/2026.
//

import CryptoKit
import Defaults
import Foundation
import PassKit
import ZIPFoundation

enum PassError: Error {
	case templateNotFound
	case invalidJSON
	case signingFailed
	case zipFailed
}

typealias JSON = [String: Any]

func generatePass() throws -> URL {
	// get data
	let subjects = Defaults[.timetable]
	let name = Defaults[.userDisplayName]

	let fileManager = FileManager.default

	// 1. Locate the .pkpasstemplate in your App Bundle
	guard let templateURL = Bundle.main.url(forResource: "Shared Timetable", withExtension: "pkpasstemplate") else {
		throw PassError.templateNotFound
	}

	// 2. Set up a temporary working directory
	let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
	let passWorkingURL = tempDir.appendingPathComponent("Timetable Pass.pass")
	try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
	try fileManager.copyItem(at: templateURL, to: passWorkingURL)

	// 3. create pass.json
	let passJSONURL = passWorkingURL.appendingPathComponent("pass.json")
	let rawData = try Data(contentsOf: passJSONURL)

	var passDict = try JSONDecoder().decode(
		JSON.self,
		from: rawData
	)

	// MARK: - Encode data

	// make userInfo array
	var userInfo = passDict["userInfo"] as? [String: Any] ?? [String: Any]()

	// Set subject data
	if let encodedData = try? JSONEncoder().encode(subjects),
	   let jsonString = String(data: encodedData, encoding: .utf8)
	{
		userInfo["rawTimetableData"] = String(jsonString)
	}

	// Set serial number for the pass
	passDict["serialNumber"] = DeviceIDProvider().getDeviceID()

	// Set date
	let dateFormatter = ISO8601DateFormatter()
	let sharedDate = dateFormatter.string(from: Date())

	passDict["userInfo"] = userInfo

	for passType in ["generic", "posterGeneric"] {
		if var subField = passDict[passType] as? [String: Any] {
			if var primaryFields = subField["primaryFields"] as? [[String: Any]] {
				for (index, field) in primaryFields.enumerated() {
					if let key = field["key"] as? String {
						if key == "name" {
							primaryFields[index]["value"] = "\(name)'s Timetable"
						} else if key == "shared" {
							primaryFields[index]["value"] = sharedDate
						}
					}
				}
				subField["primaryFields"] = primaryFields
			}

			let subjectBackFields: [[String: Any]] = subjects.map {
				["key": $0.id, "label": $0.id, "value": "\($0.slots.count) slots"]
			}

			let customBackFields: [[String: Any]] = [
				["key": "sender", "label": "Sender", "value": name],
			] + subjectBackFields + [["key": "amountOfSubjects", "label": "Total Subjects", "value": subjects.count]]

			// set the backfields to the json
			subField["backFields"] = customBackFields

			// set all this back into the json
			passDict[passType] = subField

		}
	}


	print(passDict)

	// Write the modified JSON back into the working folder
	let modifiedJSONData = try JSONSerialization.data(withJSONObject: passDict, options: .prettyPrinted)
	try modifiedJSONData.write(to: passJSONURL)

	// Remove tooling.json if it exists
	let toolingURL = passWorkingURL.appendingPathComponent("tooling.json")
	try? FileManager.default.removeItem(at: toolingURL)

	// 4. Generate manifest.json (SHA-1 hashes of all files in the folder)
	var manifest = [String: String]()
	let files = try fileManager.contentsOfDirectory(atPath: passWorkingURL.path)

	for file in files {
		guard file != ".DS_Store" && file != "manifest.json" && file != "signature" else { continue }
		let fileURL = passWorkingURL.appendingPathComponent(file)

		var isDirectory: ObjCBool = false
		if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
			continue
		}

		let fileData = try Data(contentsOf: fileURL)
		let hash = Insecure.SHA1.hash(data: fileData)
		let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
		manifest[file] = hashString
	}

	let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
	let manifestURL = passWorkingURL.appendingPathComponent("manifest.json")
	try manifestData.write(to: manifestURL)

	// 5. Sign the manifest using your OpenSSL function
	let signatureURL = passWorkingURL.appendingPathComponent("signature")
	do {
		let signatureData = try signDataWithBundledKey(manifestData)
		try signatureData.write(to: signatureURL)
	} catch {
		print("Cryptographic signing failed: \(error)")
		throw PassError.signingFailed
	}

	// 6. Compress everything into a .pkpass file safely flattening the root directory
	let finalPkpassURL = tempDir.appendingPathComponent("Timetable.pkpass")

	do {
		try fileManager.zipItem(at: passWorkingURL, to: finalPkpassURL, shouldKeepParent: false)
		return finalPkpassURL
	} catch {
		print("Zipping up your .pkpass archive failed: \(error)")
		throw PassError.zipFailed
	}
}
