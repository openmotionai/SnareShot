import XCTest
import UIKit
@testable import SnareShot

final class DiffEngineTests: XCTestCase {

    private let engine = DiffEngine()

    // MARK: - Helpers

    private func solidImage(color: UIColor, size: CGSize = CGSize(width: 10, height: 10)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Match

    func testIdenticalImagesMatch() {
        let image = solidImage(color: .red)
        let result = engine.compare(expected: image, actual: image, tolerance: 0)
        if case .match = result {
            // pass
        } else {
            XCTFail("Expected match for identical images")
        }
    }

    func testIdenticalBlueImagesMatch() {
        let a = solidImage(color: .blue)
        let b = solidImage(color: .blue)
        let result = engine.compare(expected: a, actual: b, tolerance: 0)
        if case .match = result {
            // pass
        } else {
            XCTFail("Expected match for identical blue images")
        }
    }

    // MARK: - Mismatch

    func testDifferentColorsMismatch() {
        let red = solidImage(color: .red)
        let blue = solidImage(color: .blue)
        let result = engine.compare(expected: red, actual: blue, tolerance: 0)
        if case .mismatch(let pct, _, _) = result {
            XCTAssertEqual(pct, 1.0, accuracy: 0.01, "All pixels should differ")
        } else {
            XCTFail("Expected mismatch for different colors")
        }
    }

    func testDifferentSizesMismatch() {
        let small = solidImage(color: .red, size: CGSize(width: 10, height: 10))
        let big = solidImage(color: .red, size: CGSize(width: 20, height: 20))
        let result = engine.compare(expected: small, actual: big, tolerance: 0)
        if case .mismatch(let pct, _, _) = result {
            XCTAssertEqual(pct, 1.0, "Size mismatch should be 100% diff")
        } else {
            XCTFail("Expected mismatch for different sizes")
        }
    }

    // MARK: - Tolerance

    func testSlightDifferencePassesWithTolerance() {
        let a = solidImage(color: UIColor(white: 0.5, alpha: 1))
        let b = solidImage(color: UIColor(white: 0.51, alpha: 1))
        let result = engine.compare(expected: a, actual: b, tolerance: 0.05)
        if case .match = result {
            // pass
        } else {
            XCTFail("Expected match with tolerance for similar colors")
        }
    }

    func testSlightDifferenceFailsWithZeroTolerance() {
        let a = solidImage(color: UIColor(white: 0.5, alpha: 1))
        let b = solidImage(color: UIColor(white: 0.51, alpha: 1))
        let result = engine.compare(expected: a, actual: b, tolerance: 0)
        if case .mismatch = result {
            // pass
        } else {
            XCTFail("Expected mismatch with zero tolerance")
        }
    }

    // MARK: - Composite image

    func testCompositeImageHasTripleWidth() {
        let red = solidImage(color: .red, size: CGSize(width: 10, height: 10))
        let blue = solidImage(color: .blue, size: CGSize(width: 10, height: 10))
        let result = engine.compare(expected: red, actual: blue, tolerance: 0)
        if case .mismatch(_, _, let composite) = result {
            XCTAssertEqual(composite.size.width, 30, accuracy: 1)
            XCTAssertEqual(composite.size.height, 10, accuracy: 1)
        } else {
            XCTFail("Expected mismatch")
        }
    }

    // MARK: - Diff percentage

    func testPartialDiff() {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let imageA = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let imageB = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 5))
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 5, width: 10, height: 5))
        }
        let result = engine.compare(expected: imageA, actual: imageB, tolerance: 0)
        if case .mismatch(let pct, _, _) = result {
            XCTAssertEqual(pct, 0.5, accuracy: 0.05, "Bottom half differs = ~50%")
        } else {
            XCTFail("Expected mismatch")
        }
    }
}
