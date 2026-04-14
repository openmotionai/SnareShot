import XCTest
@testable import SnareShot

final class DeviceConfigTests: XCTestCase {

    func testIPhone15ProScreenSize() {
        let config = DeviceConfig.iPhone15Pro
        XCTAssertEqual(config.screenSize.width, 393)
        XCTAssertEqual(config.screenSize.height, 852)
    }

    func testIPhone15ProScale() {
        XCTAssertEqual(DeviceConfig.iPhone15Pro.scale, 3)
    }

    func testIPhoneSE3ScreenSize() {
        let config = DeviceConfig.iPhoneSE3
        XCTAssertEqual(config.screenSize.width, 375)
        XCTAssertEqual(config.screenSize.height, 667)
    }

    func testIPhoneSE3Scale() {
        XCTAssertEqual(DeviceConfig.iPhoneSE3.scale, 2)
    }

    func testIPadPro12ScreenSize() {
        let config = DeviceConfig.iPadPro12
        XCTAssertEqual(config.screenSize.width, 1024)
        XCTAssertEqual(config.screenSize.height, 1366)
    }

    func testDisplayNames() {
        XCTAssertEqual(DeviceConfig.iPhone15Pro.displayName, "iPhone15Pro")
        XCTAssertEqual(DeviceConfig.iPhoneSE3.displayName, "iPhoneSE3")
        XCTAssertEqual(DeviceConfig.iPadPro12.displayName, "iPadPro12")
    }

    func testAllCases() {
        XCTAssertEqual(DeviceConfig.allCases.count, 6)
    }

    func testSafeAreaInsets() {
        let config = DeviceConfig.iPhone15Pro
        XCTAssertGreaterThan(config.safeAreaInsets.top, 0)
        XCTAssertGreaterThan(config.safeAreaInsets.bottom, 0)
    }

    func testFilenameSuffix() {
        XCTAssertEqual(DeviceConfig.iPhone15Pro.filenameSuffix, "iPhone15Pro")
        XCTAssertEqual(DeviceConfig.iPhone15ProMax.filenameSuffix, "iPhone15ProMax")
    }
}
