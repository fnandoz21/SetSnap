import XCTest
@testable import SetSnap

final class SetSnapTests: XCTestCase {
    func testDefaultSettings() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.maxAssetsPerBatch, 20)
        XCTAssertTrue(settings.processOnlyOnWiFi)
    }
}
