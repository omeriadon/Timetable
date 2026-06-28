//
//   generatePass.swift
//   Shared
//
//   Created by Adon Omeri on 21/6/2026.
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

nonisolated func generatePass() async throws -> URL {
	let startTime = ContinuousClock.now

	// get data
	let subjects = await Defaults[.timetable]
	let name = await Defaults[.userDisplayName]

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

	// 3. Read and parse pass.json using JSONSerialization (since [String: Any] isn't Decodable)
	let passJSONURL = passWorkingURL.appendingPathComponent("pass.json")
	let rawData = try Data(contentsOf: passJSONURL)

	guard var passDict = try JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] else {
		throw PassError.invalidJSON
	}

	// MARK: - Encode data

	// Handle userInfo safely
	var userInfo = passDict["userInfo"] as? [String: Any] ?? [String: Any]()
	if let encodedData = try? JSONEncoder().encode(subjects),
	   let jsonString = String(data: encodedData, encoding: .utf8)
	{
		userInfo["rawTimetableData"] = jsonString
	}
	passDict["userInfo"] = userInfo

	// Set serial number
	passDict["serialNumber"] = await DeviceIDProvider().getDeviceID()

	// Set date
	let dateFormatter = ISO8601DateFormatter()
	dateFormatter.formatOptions = [.withInternetDateTime]
	let sharedDate = dateFormatter.string(from: Date())

	// Loop through pass styles and update fields cleanly
	for passType in ["generic", "posterGeneric"] {
		if var subField = passDict[passType] as? [String: Any] {
			// 1. Update Primary Fields safely
			if var primaryFields = subField["primaryFields"] as? [[String: Any]] {
				for index in primaryFields.indices {
					if let key = primaryFields[index]["key"] as? String {
						if key == "name" {
							primaryFields[index]["value"] = "\(name)'s Timetable"
						} else if key == "shared" {
							primaryFields[index]["value"] = sharedDate
						}
					}
				}
				subField["primaryFields"] = primaryFields
			}

			// 2. Append to Back Fields instead of wiping them out
			var currentBackFields = subField["backFields"] as? [[String: Any]] ?? [[String: Any]]()

			// Generate your dynamic subject rows
			let subjectBackFields: [[String: Any]] = subjects.map {
				["key": $0.id, "label": $0.id, "value": "\($0.slots.count) slots"]
			}

			let subjectsSummaryString: String = subjects
				.map(\.id)
				.joined(separator: ", ")

			let subjectsSummaryItem: [String: Any] = [
				"key": "subjectsSummary",
				"label": "Subjects Summary",
				"value": subjectsSummaryString,
			]

			// Build the new additions for the back fields
			let contextBackFields: [[String: Any]] = [
				["key": "sender", "label": "Sender", "value": name],

				[
					"key": "shared",
					"label": "Shared On",
					"value": sharedDate,
					"dateStyle": "PKDateStyleLong",
					"timeStyle": "PKDateStyleNone",
				],
			] + subjectBackFields + [
				["key": "amountOfSubjects", "label": "Total Subjects", "value": subjects.count],
				subjectsSummaryItem,
			]

			// To prevent duplicate keys if this runs multiple times, filter out existing matching keys
			let newKeys = contextBackFields.compactMap { $0["key"] as? String }
			currentBackFields.removeAll { field in
				if let key = field["key"] as? String {
					return newKeys.contains(key)
				}
				return false
			}

			// Merge backfields together
			currentBackFields.append(contentsOf: contextBackFields)
			subField["backFields"] = currentBackFields

			// 3. Update Front Footer safely (as an array containing a layout dictionary)
			if var footerFields = subField["footerFields"] as? [[String: Any]] {
				var updated = false
				for index in footerFields.indices {
					if let key = footerFields[index]["key"] as? String, key == "subjectsSummary" {
						footerFields[index]["value"] = subjectsSummaryString
						updated = true
					}
				}
				// If footer array exists but key isn't in it yet, append it properly
				if !updated {
					footerFields.append([
						"key": "subjectsSummary",
						"label": "Subjects Summary",
						"textAlignment": "PKTextAlignmentNatural",
						"value": subjectsSummaryString,
					])
				}
				subField["footerFields"] = footerFields
			} else {
				// If the pass layout type doesn't have footers at all, initialize it as a proper array
				subField["footerFields"] = [[
					"key": "subjectsSummary",
					"label": "Subjects Summary",
					"textAlignment": "PKTextAlignmentNatural",
					"value": subjectsSummaryString,
				]]
			}

			// Save back into main dictionary
			passDict[passType] = subField
		}
	}

	// This print statement will now look like clean Swift dictionaries, no __NSArrayM!
	Print(passDict)

	// Write the modified JSON back into the working folder
	let modifiedJSONData = try JSONSerialization.data(withJSONObject: passDict, options: .prettyPrinted)
	try modifiedJSONData.write(to: passJSONURL)

	// Remove tooling.json if it exists
	let toolingURL = passWorkingURL.appendingPathComponent("tooling.json")
	try? fileManager.removeItem(at: toolingURL)

	// 4. Generate manifest.json (SHA-1 hashes of all files in the folder)
	var manifest = [String: String]()
	let files = try fileManager.contentsOfDirectory(atPath: passWorkingURL.path)

	for file in files {
		guard file != ".DS_Store", file != "manifest.json", file != "signature" else { continue }
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

	// 5. Sign the manifest
	let signatureURL = passWorkingURL.appendingPathComponent("signature")
	do {
		let signatureData = try signDataWithBundledKey(manifestData)
		try signatureData.write(to: signatureURL)
	} catch {
		PrintError("Cryptographic signing failed: \(error)")
		throw PassError.signingFailed
	}

	// 6. Compress everything into a .pkpass file safely flattening the root directory
	let finalPkpassURL = tempDir.appendingPathComponent("Timetable.pkpass")

	do {
		try fileManager.zipItem(at: passWorkingURL, to: finalPkpassURL, shouldKeepParent: false)

		let elapsedTime = ContinuousClock.now - startTime
		Print("Pass generation took: \(elapsedTime)")
		return finalPkpassURL
	} catch {
		PrintError("Zipping up your .pkpass archive failed: \(error)")
		throw PassError.zipFailed
	}
}
