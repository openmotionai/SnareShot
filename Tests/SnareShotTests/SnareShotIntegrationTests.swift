import XCTest
import SwiftUI
import UIKit
@testable import SnareShot

final class SnareShotIntegrationTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnareShotIntegration-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        SnareShotState.shared.reset()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeSnapshotter() -> Snapshotter {
        return Snapshotter()
    }

    private func makeFileManager() -> GoldenFileManager {
        return GoldenFileManager(snapshotsBaseDir: tempDir)
    }

    // MARK: - Rendering

    func testRenderSwiftUIView() {
        let view = Color.red.frame(width: 100, height: 100)
        let snapshotter = makeSnapshotter()
        let combo = VariantCombo(colorScheme: .light, contentSizeCategory: .large, orientation: .portrait)
        let image = snapshotter.render(
            target: .swiftUI(AnyView(view)),
            device: .iPhone15Pro,
            variant: combo
        )
        XCTAssertEqual(image.size.width, 393, accuracy: 1)
        XCTAssertEqual(image.size.height, 852, accuracy: 1)
    }

    func testRenderUIKitViewController() {
        let vc = UIViewController()
        vc.view.backgroundColor = .blue
        let snapshotter = makeSnapshotter()
        let combo = VariantCombo()
        let image = snapshotter.render(
            target: .viewController(vc),
            device: .iPhoneSE3,
            variant: combo
        )
        XCTAssertEqual(image.size.width, 375, accuracy: 1)
        XCTAssertEqual(image.size.height, 667, accuracy: 1)
    }

    func testRenderLandscape() {
        let view = Color.green.frame(width: 100, height: 100)
        let snapshotter = makeSnapshotter()
        let combo = VariantCombo(orientation: .landscape)
        let image = snapshotter.render(
            target: .swiftUI(AnyView(view)),
            device: .iPhone15Pro,
            variant: combo
        )
        XCTAssertEqual(image.size.width, 852, accuracy: 1)
        XCTAssertEqual(image.size.height, 393, accuracy: 1)
    }

    // MARK: - Record + Verify Round Trip

    func testRecordAndVerifyRoundTrip() throws {
        let view = Color.red.frame(width: 50, height: 50)
        let snapshotter = makeSnapshotter()
        let fileManager = makeFileManager()
        let diffEngine = DiffEngine()
        let combo = VariantCombo()

        let image = snapshotter.render(
            target: .swiftUI(AnyView(view)),
            device: .iPhone15Pro,
            variant: combo
        )
        let url = fileManager.goldenURL(
            testClass: "RoundTrip",
            testMethod: "test",
            device: .iPhone15Pro,
            variant: combo,
            counter: 0
        )
        try fileManager.save(image: image, to: url)

        let actual = snapshotter.render(
            target: .swiftUI(AnyView(view)),
            device: .iPhone15Pro,
            variant: combo
        )
        let expected = try fileManager.load(from: url)
        let result = diffEngine.compare(expected: expected, actual: actual, tolerance: 0)

        if case .match = result {
            // pass
        } else {
            XCTFail("Same view rendered twice should match")
        }
    }

    // MARK: - Variant Expansion File Count

    func testVariantExpansionCreatesCorrectFileCount() throws {
        let view = Color.blue.frame(width: 20, height: 20)
        let snapshotter = makeSnapshotter()
        let fileManager = makeFileManager()
        let matrix = VariantMatrix(variants: [.lightDark, .dynamicType([.large, .accessibilityLarge])])
        let combos = matrix.expand()

        for combo in combos {
            let image = snapshotter.render(
                target: .swiftUI(AnyView(view)),
                device: .iPhone15Pro,
                variant: combo
            )
            let url = fileManager.goldenURL(
                testClass: "VariantTest",
                testMethod: "testVariants",
                device: .iPhone15Pro,
                variant: combo,
                counter: 0
            )
            try fileManager.save(image: image, to: url)
        }

        let allURLs = fileManager.allSnapshotURLs()
        XCTAssertEqual(allURLs.count, 4, "lightDark x 2 dynamicType sizes = 4 files")
    }

    // MARK: - Gallery Report

    func testGalleryReportGenerated() throws {
        let view = Color.orange.frame(width: 10, height: 10)
        let snapshotter = makeSnapshotter()
        let fileManager = makeFileManager()
        let combo = VariantCombo()

        let image = snapshotter.render(
            target: .swiftUI(AnyView(view)),
            device: .iPhone15Pro,
            variant: combo
        )
        let url = fileManager.goldenURL(
            testClass: "GalleryTest",
            testMethod: "testGallery",
            device: .iPhone15Pro,
            variant: combo,
            counter: 0
        )
        try fileManager.save(image: image, to: url)

        let galleryURL = GalleryReportGenerator.generate(snapshotsDir: tempDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: galleryURL.path))

        let html = try String(contentsOf: galleryURL, encoding: .utf8)
        XCTAssertTrue(html.contains("testGallery"))
        XCTAssertTrue(html.contains("SnareShot Gallery"))
    }

    // MARK: - Mismatch Detection

    func testMismatchProducesDiffImage() throws {
        let diffEngine = DiffEngine()

        // Use solid-color images for a deterministic mismatch test
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        let redImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let blueImage = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let result = diffEngine.compare(expected: redImage, actual: blueImage, tolerance: 0)

        if case .mismatch(let pct, _, let composite) = result {
            XCTAssertGreaterThan(pct, 0)
            XCTAssertGreaterThan(composite.size.width, 0)
        } else {
            XCTFail("Red vs blue should mismatch")
        }
    }
}
