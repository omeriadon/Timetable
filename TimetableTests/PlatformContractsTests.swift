import XCTest

final class PlatformContractsTests: XCTestCase {
	func testAuthorityPolicy() {
		XCTAssertTrue(Platform.iOS.isAuthoritative)
		XCTAssertFalse(Platform.iPadOS.isAuthoritative)
		XCTAssertFalse(Platform.macOS.isAuthoritative)
		XCTAssertFalse(Platform.watchOS.isAuthoritative)
		XCTAssertTrue(Platform.iPadOS.allowsNotificationSettings)
		XCTAssertFalse(Platform.macOS.allowsOwnerMutation)
	}

	func testInstallationIDsAreStableAndPlatformScoped() throws {
		let defaults = try XCTUnwrap(UserDefaults(suiteName: "TimetableTests.\(UUID().uuidString)"))
		let provider = ClientIdentityProvider(defaults: defaults)
		let phone = provider.identity(for: .iOS)
		let phoneAgain = provider.identity(for: .iOS)
		let watch = provider.identity(for: .watchOS)
		XCTAssertEqual(phone, phoneAgain)
		XCTAssertNotEqual(phone.installationID, watch.installationID)
		XCTAssertEqual(watch.platform, .watchOS)
	}

	func testAuthPayloadsEncodeServerIdentity() throws {
		let request = LoginRequest(email: "a@example.com", password: "secret", platform: Platform.iPadOS.rawValue, installationID: "ipad-install")
		let data = try JSONEncoder().encode(request)
		let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
		XCTAssertEqual(object["platform"] as? String, "iPadOS")
		XCTAssertEqual(object["installationID"] as? String, "ipad-install")
	}

	func testRefreshPayloadRemainsTokenOnly() throws {
		let data = try JSONEncoder().encode(RefreshRequest(refreshToken: "refresh"))
		let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
		XCTAssertEqual(Set(object.keys), ["refreshToken"])
	}
}
