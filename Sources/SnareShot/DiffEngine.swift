import UIKit

// MARK: - DiffResult

public enum DiffResult {
    case match
    case mismatch(diffPercentage: Double, diffImage: UIImage, compositeImage: UIImage)
}

// MARK: - Protocol

public protocol DiffEngineProtocol {
    func compare(expected: UIImage, actual: UIImage, tolerance: Double) -> DiffResult
}

// MARK: - Implementation

public final class DiffEngine: DiffEngineProtocol {

    public init() {}

    public func compare(expected: UIImage, actual: UIImage, tolerance: Double) -> DiffResult {
        guard let expectedCG = expected.cgImage,
              let actualCG = actual.cgImage else {
            return .mismatch(
                diffPercentage: 1.0,
                diffImage: expected,
                compositeImage: expected
            )
        }

        let expectedWidth = expectedCG.width
        let expectedHeight = expectedCG.height
        let actualWidth = actualCG.width
        let actualHeight = actualCG.height

        if expectedWidth != actualWidth || expectedHeight != actualHeight {
            let composite = makeComposite(expected: expected, actual: actual, diff: actual)
            return .mismatch(diffPercentage: 1.0, diffImage: actual, compositeImage: composite)
        }

        let width = expectedWidth
        let height = expectedHeight
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalPixels = width * height

        guard let expectedData = pixelData(from: expectedCG, width: width, height: height, bytesPerRow: bytesPerRow),
              let actualData = pixelData(from: actualCG, width: width, height: height, bytesPerRow: bytesPerRow) else {
            return .mismatch(
                diffPercentage: 1.0,
                diffImage: expected,
                compositeImage: expected
            )
        }

        var diffPixels = 0
        var diffBytes = [UInt8](repeating: 0, count: width * height * 4)

        for i in 0..<totalPixels {
            let offset = i * 4
            let rDiff = abs(Int(expectedData[offset]) - Int(actualData[offset]))
            let gDiff = abs(Int(expectedData[offset + 1]) - Int(actualData[offset + 1]))
            let bDiff = abs(Int(expectedData[offset + 2]) - Int(actualData[offset + 2]))
            let aDiff = abs(Int(expectedData[offset + 3]) - Int(actualData[offset + 3]))

            let maxDiff = Double(max(rDiff, gDiff, bDiff, aDiff)) / 255.0

            if maxDiff > tolerance {
                diffPixels += 1
                diffBytes[offset] = 255     // R
                diffBytes[offset + 1] = 0   // G
                diffBytes[offset + 2] = 0   // B
                diffBytes[offset + 3] = 255 // A
            } else {
                diffBytes[offset] = 0
                diffBytes[offset + 1] = 0
                diffBytes[offset + 2] = 0
                diffBytes[offset + 3] = 0
            }
        }

        if diffPixels == 0 {
            return .match
        }

        let diffPercentage = Double(diffPixels) / Double(totalPixels)
        let diffImage = imageFromPixelData(diffBytes, width: width, height: height)
        let composite = makeComposite(expected: expected, actual: actual, diff: diffImage)

        return .mismatch(
            diffPercentage: diffPercentage,
            diffImage: diffImage,
            compositeImage: composite
        )
    }

    // MARK: - Pixel data extraction

    private func pixelData(from cgImage: CGImage, width: Int, height: Int, bytesPerRow: Int) -> [UInt8]? {
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }

    private func imageFromPixelData(_ data: [UInt8], width: Int, height: Int) -> UIImage {
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var mutableData = data
        guard let context = CGContext(
            data: &mutableData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
              let cgImage = context.makeImage() else {
            return UIImage()
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - 3-panel composite

    private func makeComposite(expected: UIImage, actual: UIImage, diff: UIImage) -> UIImage {
        let width = max(expected.size.width, actual.size.width, diff.size.width)
        let height = max(expected.size.height, actual.size.height, diff.size.height)
        let totalWidth = width * 3
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: height))
        return renderer.image { _ in
            expected.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            actual.draw(in: CGRect(x: width, y: 0, width: width, height: height))
            diff.draw(in: CGRect(x: width * 2, y: 0, width: width, height: height))
        }
    }
}
