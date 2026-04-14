import XCTest
import UIKit
@testable import SnareShot

final class FailureReportGeneratorTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnareShotFailureTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeDiffImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 10))
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 30, height: 10))
        }
    }

    private func saveDiffImage(named: String) throws -> URL {
        let url = tempDir.appendingPathComponent(named)
        let image = makeDiffImage()
        try image.pngData()!.write(to: url)
        return url
    }

    func testGeneratesHTMLFile() throws {
        let diffURL = try saveDiffImage(named: "test1_diff.png")
        let failures = [
            FailureReportGenerator.FailureEntry(
                testClass: "LoginTests",
                snapshotName: "testLogin_iPhone15Pro_dark_large_portrait",
                diffPercentage: 0.15,
                diffImageURL: diffURL
            )
        ]
        let outputURL = FailureReportGenerator.generate(failures: failures, outputDir: tempDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testHTMLContainsFailureDetails() throws {
        let diffURL = try saveDiffImage(named: "test1_diff.png")
        let failures = [
            FailureReportGenerator.FailureEntry(
                testClass: "LoginTests",
                snapshotName: "testLogin_iPhone15Pro_dark_large_portrait",
                diffPercentage: 0.15,
                diffImageURL: diffURL
            )
        ]
        let outputURL = FailureReportGenerator.generate(failures: failures, outputDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("LoginTests"))
        XCTAssertTrue(html.contains("testLogin"))
        XCTAssertTrue(html.contains("15.0%"))
    }

    func testHTMLGroupsByTestClass() throws {
        let diff1 = try saveDiffImage(named: "diff1.png")
        let diff2 = try saveDiffImage(named: "diff2.png")
        let failures = [
            FailureReportGenerator.FailureEntry(
                testClass: "LoginTests", snapshotName: "testLogin", diffPercentage: 0.1, diffImageURL: diff1
            ),
            FailureReportGenerator.FailureEntry(
                testClass: "SettingsTests", snapshotName: "testSettings", diffPercentage: 0.2, diffImageURL: diff2
            ),
        ]
        let outputURL = FailureReportGenerator.generate(failures: failures, outputDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("LoginTests"))
        XCTAssertTrue(html.contains("SettingsTests"))
    }

    func testHTMLHasDarkTheme() throws {
        let diffURL = try saveDiffImage(named: "diff.png")
        let failures = [
            FailureReportGenerator.FailureEntry(
                testClass: "A", snapshotName: "test", diffPercentage: 0.5, diffImageURL: diffURL
            )
        ]
        let outputURL = FailureReportGenerator.generate(failures: failures, outputDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("#0d0d1a"))
    }

    func testHTMLContainsBase64DiffImage() throws {
        let diffURL = try saveDiffImage(named: "diff.png")
        let failures = [
            FailureReportGenerator.FailureEntry(
                testClass: "A", snapshotName: "test", diffPercentage: 0.5, diffImageURL: diffURL
            )
        ]
        let outputURL = FailureReportGenerator.generate(failures: failures, outputDir: tempDir)
        let html = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(html.contains("data:image/png;base64,"))
    }
}
