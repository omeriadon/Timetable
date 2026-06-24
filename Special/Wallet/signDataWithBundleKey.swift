//
//  signDataWithBundleKey.swift
//  Timetable
//
//  Created by Adon Omeri on 21/6/2026.
//

import Foundation
import OpenSSL

enum SigningError: Error {
	case resourceNotFound
	case cryptoInitializationFailed
	case parsePrivateKeyFailed
	case parseCertificateFailed
	case signingFailed
	case dataExtractionFailed
}

/// Helper to extract the concrete OpenSSL error string
func getOpenSSLError() -> String {
	let errorCode = ERR_get_error()
	if errorCode == 0 { return "No OpenSSL error code recorded." }

	let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
	defer { buffer.deallocate() }

	if let result = ERR_error_string(errorCode, buffer) {
		return String(cString: result)
	}
	return "Unknown OpenSSL Error (Code: \(errorCode))"
}

nonisolated func signDataWithBundledKey(_ manifestData: Data) throws -> Data {
	// 1. Initialize OpenSSL configuration so it recognizes key formats
	OSSL_PROVIDER_load(nil, "default")
	OpenSSL_add_all_algorithms()

	// 2. Locate the .pem keys copied to your main app bundle
	guard let passKeyURL = Bundle.main.url(forResource: "pass", withExtension: "pem"),
	      let walletCertURL = Bundle.main.url(forResource: "wallet_pass", withExtension: "pem")
	else {
		throw SigningError.resourceNotFound
	}

	let passKeyData = try Data(contentsOf: passKeyURL)
	let walletCertData = try Data(contentsOf: walletCertURL)

	// 3. Initialize OpenSSL memory buffers
	let manifestBio = BIO_new_mem_buf((manifestData as NSData).bytes, Int32(manifestData.count))
	let pkeyBio = BIO_new_mem_buf((passKeyData as NSData).bytes, Int32(passKeyData.count))
	let certBio = BIO_new_mem_buf((walletCertData as NSData).bytes, Int32(walletCertData.count))

	defer {
		BIO_free(manifestBio)
		BIO_free(pkeyBio)
		BIO_free(certBio)
	}

	// 4. Try parsing the private key
	guard let pkey = PEM_read_bio_PrivateKey(pkeyBio, nil, nil, nil) else {
		print("❌ OpenSSL Private Key Parsing Failed!")
		print("Detailed OpenSSL Error: \(getOpenSSLError())")
		throw SigningError.parsePrivateKeyFailed
	}
	print("✅ Private key parsed successfully: \(pkey)")
	defer { EVP_PKEY_free(pkey) }

	// 5. Try parsing the certificate
	guard let cert = PEM_read_bio_X509(certBio, nil, nil, nil) else {
		print("❌ OpenSSL Certificate Parsing Failed!")
		print("Detailed OpenSSL Error: \(getOpenSSLError())")
		throw SigningError.parseCertificateFailed
	}
	print("✅ Certificate parsed successfully: \(cert)")
	defer { X509_free(cert) }

	// 6. Generate the PKCS7 Signature envelope
	let signingFlags: Int32 = PKCS7_DETACHED | PKCS7_BINARY

	guard let pkcs7Structure = PKCS7_sign(cert, pkey, nil, manifestBio, signingFlags) else {
		print("❌ PKCS7 Signing Failed!")
		print("Detailed OpenSSL Error: \(getOpenSSLError())")
		throw SigningError.signingFailed
	}
	defer { PKCS7_free(pkcs7Structure) }

	// 7. Convert to DER format
	let outputBio = BIO_new(BIO_s_mem())
	defer { BIO_free(outputBio) }

	guard i2d_PKCS7_bio(outputBio, pkcs7Structure) == 1 else {
		throw SigningError.dataExtractionFailed
	}

	// 8. Extract raw bytes
	var internalBuffer: UnsafeMutablePointer<Int8>? = nil
	let dataLength = BIO_ctrl(outputBio, BIO_CTRL_INFO, 0, &internalBuffer)

	if let safeBuffer = internalBuffer, dataLength > 0 {
		return Data(bytes: safeBuffer, count: Int(dataLength))
	} else {
		throw SigningError.dataExtractionFailed
	}
}
