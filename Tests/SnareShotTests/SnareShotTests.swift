import XCTest
@testable import SnareShot

final class SnareShotTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(SnareShot.version, "0.1.0")
    }
}
