import XCTest
import UIKit
@testable import SnareShot

final class GalleryReportGeneratorTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnareShotGalleryTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func createTestPNG(named: String, in subdir: String) throws -> URL {
        let dir = tempDir.appendingPathComponent(subdir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(named)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        try image.pngData()!.write(to: url)
        return url
    }

    func testGeneratesHTMLFile() throws {
        try createTestPNG(named: "testLogin_iPhone15Pro_light_large_portrait.png", in: "LoginTests")
        try createTestPNG(named: "testLogin_iPhone15Pro_dark_large_portrait.png", in: "LoginTests")
        let outputURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testHTMLContainsSnapshotNames() throws {
        try createTestPNG(named: "testLogin_iPhone15Pro_light_large_portrait.png", in: "LoginTests")
        let outputURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("testLogin"))
        XCTAssertTrue(html.contains("LoginTests"))
    }

    func testHTMLContainsSnapshotCount() throws {
        try createTestPNG(named: "test1_iPhone15Pro_light_large_portrait.png", in: "A")
        try createTestPNG(named: "test2_iPhone15Pro_light_large_portrait.png", in: "B")
        try createTestPNG(named: "test3_iPhoneSE3_dark_large_portrait.png", in: "B")
        let outputURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("3 screens"))
    }

    func testHTMLHasDarkTheme() throws {
        try createTestPNG(named: "test1_iPhone15Pro_light_large_portrait.png", in: "A")
        let outputURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("#0d0d1a"))
    }

    func testHTMLContainsBase64Images() throws {
        try createTestPNG(named: "test1_iPhone15Pro_light_large_portrait.png", in: "A")
        let outputURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("data:image/png;base64,"))
    }

    func testHTMLContainsDeviceBadge() throws {
        try createTestPNG(named: "test1_iPhone15Pro_light_large_portrait.png", in: "A")
        let outputURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("iPhone15Pro"))
    }
}
