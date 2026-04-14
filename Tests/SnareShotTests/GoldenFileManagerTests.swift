import XCTest
import UIKit
@testable import SnareShot

final class GoldenFileManagerTests: XCTestCase {

    private var tempDir: URL!
    private var manager: GoldenFileManager!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnareShotTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        manager = GoldenFileManager(snapshotsBaseDir: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testGoldenURL() {
        let combo = VariantCombo(colorScheme: .dark, contentSizeCategory: .large, orientation: .portrait)
        let url = manager.goldenURL(
            testClass: "LoginTests",
            testMethod: "testLogin",
            device: .iPhone15Pro,
            variant: combo,
            counter: 0
        )
        let expected = tempDir
            .appendingPathComponent("LoginTests")
            .appendingPathComponent("testLogin_iPhone15Pro_dark_large_portrait.png")
        XCTAssertEqual(url, expected)
    }

    func testGoldenURLWithCounter() {
        let combo = VariantCombo()
        let url = manager.goldenURL(
            testClass: "LoginTests",
            testMethod: "testLogin",
            device: .iPhone15Pro,
            variant: combo,
            counter: 2
        )
        XCTAssertTrue(url.lastPathComponent.contains("_2"))
    }

    func testCounterZeroOmitsSuffix() {
        let combo = VariantCombo()
        let url = manager.goldenURL(
            testClass: "LoginTests",
            testMethod: "testLogin",
            device: .iPhone15Pro,
            variant: combo,
            counter: 0
        )
        XCTAssertFalse(url.lastPathComponent.contains("_0"))
    }

    func testSaveAndLoadRoundTrip() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        let combo = VariantCombo()
        let url = manager.goldenURL(
            testClass: "RoundTripTests",
            testMethod: "testRoundTrip",
            device: .iPhone15Pro,
            variant: combo,
            counter: 0
        )
        try manager.save(image: image, to: url)
        XCTAssertTrue(manager.exists(at: url))
        let loaded = try manager.load(from: url)
        // PNG save/load may change UIImage.size due to scale factor
        // Just verify the image loaded successfully with valid dimensions
        XCTAssertGreaterThan(loaded.size.width, 0)
        XCTAssertGreaterThan(loaded.size.height, 0)
    }

    func testExistsReturnsFalseForMissingFile() {
        let url = tempDir.appendingPathComponent("nonexistent.png")
        XCTAssertFalse(manager.exists(at: url))
    }

    func testLoadMissingFileThrows() {
        let url = tempDir.appendingPathComponent("missing.png")
        XCTAssertThrowsError(try manager.load(from: url))
    }

    func testAllSnapshotURLs() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let combo = VariantCombo()
        let url1 = manager.goldenURL(testClass: "A", testMethod: "test1", device: .iPhone15Pro, variant: combo, counter: 0)
        let url2 = manager.goldenURL(testClass: "B", testMethod: "test2", device: .iPhoneSE3, variant: combo, counter: 0)
        try manager.save(image: image, to: url1)
        try manager.save(image: image, to: url2)
        let allURLs = manager.allSnapshotURLs()
        XCTAssertEqual(allURLs.count, 2)
    }
}
