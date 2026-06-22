//
//  generatePass.swift
//  Timetable
//
//  Created by Adon Omeri on 21/6/2026.
//


import Foundation
import ZIPFoundation
import CryptoKit

enum PassError: Error {
    case templateNotFound
    case invalidJSON
    case signingFailed
    case zipFailed
}

func generatePass(timetableData: String) throws -> URL {
    let fileManager = FileManager.default
    
    // 1. Locate the .pkpasstemplate in your App Bundle
    guard let templateURL = Bundle.main.url(forResource: "Shared Timetable", withExtension: "pkpasstemplate") else {
        throw PassError.templateNotFound
    }
    
    // 2. Set up a temporary working directory
    let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let passWorkingURL = tempDir.appendingPathComponent("MyPass.pass")
    
    try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
    try fileManager.copyItem(at: templateURL, to: passWorkingURL)
    
    // 3. Inject timetableData into pass.json
    let passJSONURL = passWorkingURL.appendingPathComponent("pass.json")
    let rawJSONData = try Data(contentsOf: passJSONURL)
    
    guard var passDict = try JSONSerialization.jsonObject(with: rawJSONData, options: .mutableContainers) as? [String: Any] else {
        throw PassError.invalidJSON
    }
    
    // Dynamically update the timetable value inside the pass structure.
    // NOTE: This updates the "generic" style structure. If your Pass Designer 
    // template uses an "eventTicket" or "boardingPass" type, change the key below accordingly!
    if var generic = passDict["generic"] as? [String: Any],
       var primaryFields = generic["primaryFields"] as? [[String: Any]],
       !primaryFields.isEmpty {
        primaryFields[0]["value"] = timetableData
        generic["primaryFields"] = primaryFields
        passDict["generic"] = generic
    } else {
        // Fallback: If your layout structure is different, we can inject a backField or raw userInfo dictionary
        var generic = passDict["generic"] as? [String: Any] ?? [String: Any]()
        generic["primaryFields"] = [["key": "timetable", "label": "Timetable", "value": timetableData]]
        passDict["generic"] = generic
    }
    
    // Write the modified JSON back into the working folder
    let modifiedJSONData = try JSONSerialization.data(withJSONObject: passDict, options: .prettyPrinted)
    try modifiedJSONData.write(to: passJSONURL)

	// remove tooling.json, useless file
	let toolingURL = passWorkingURL.appendingPathComponent("tooling.json")
	try? FileManager.default.removeItem(at: toolingURL)

    // 4. Generate manifest.json (SHA-1 hashes of all files in the folder)
    var manifest = [String: String]()
    let files = try fileManager.contentsOfDirectory(atPath: passWorkingURL.path)
    
    for file in files {
        guard file != ".DS_Store" && file != "manifest.json" && file != "signature" else { continue }
        let fileURL = passWorkingURL.appendingPathComponent(file)
        
        // Skip directories if any exist inside the bundle
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

	// === DIAGNOSTIC PRINT BLOCK ===
	print("📁 --- Files being zipped into .pass directory ---")
	if let filesInFolder = try? fileManager.contentsOfDirectory(atPath: passWorkingURL.path) {
		for f in filesInFolder {
			print("  ➡️ \(f)")
		}
	}
	if let manifestString = String(data: manifestData, encoding: .utf8) {
		print("📄 --- Generated manifest.json content ---")
		print(manifestString)
	}
	// =======================================


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
		// We use zipItem(at:to:shouldKeepParent:) and set shouldKeepParent to false.
		// This ensures pass.json, manifest.json, signature, etc. are placed directly
		// at the root level of the ZIP archive instead of nested inside a folder!
		try fileManager.zipItem(at: passWorkingURL, to: finalPkpassURL, shouldKeepParent: false)
		return finalPkpassURL
	} catch {
		print("Zipping up your .pkpass archive failed: \(error)")
		throw PassError.zipFailed
	}
}
