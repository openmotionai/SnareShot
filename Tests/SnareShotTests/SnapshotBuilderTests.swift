import XCTest
import UIKit
@testable import SnareShot

final class SnapshotBuilderTests: XCTestCase {

    func testDefaultConfig() {
        let config = SnapshotConfig.defaultConfig
        XCTAssertEqual(config.devices, [.iPhone15Pro])
        XCTAssertEqual(config.variants.count, 1)
        XCTAssertEqual(config.tolerance, 0.0)
    }

    func testDevicesOverride() {
        var builder = SnapshotBuilder(target: .view(UIView()), config: .defaultConfig)
        builder = builder.devices(.iPhoneSE3, .iPadPro12)
        XCTAssertEqual(builder.resolvedConfig.devices, [.iPhoneSE3, .iPadPro12])
    }

    func testVariantsOverride() {
        var builder = SnapshotBuilder(target: .view(UIView()), config: .defaultConfig)
        builder = builder.variants(.light, .dynamicType([.extraLarge]))
        let matrix = VariantMatrix(variants: builder.resolvedConfig.variants)
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 1)
        XCTAssertEqual(combos[0].colorScheme, .light)
        XCTAssertEqual(combos[0].contentSizeCategory, .extraLarge)
    }

    func testToleranceOverride() {
        var builder = SnapshotBuilder(target: .view(UIView()), config: .defaultConfig)
        builder = builder.tolerance(0.02)
        XCTAssertEqual(builder.resolvedConfig.tolerance, 0.02)
    }

    func testIsRecordingFromEnvironment() {
        let isRecording = SnapshotBuilder.isRecordMode
        let env = ProcessInfo.processInfo.environment["SNARESHOT_RECORD"]
        XCTAssertEqual(isRecording, env == "1")
    }
}
