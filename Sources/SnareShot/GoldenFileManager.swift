import UIKit

// MARK: - Protocol

public protocol GoldenFileManaging {
    func goldenURL(testClass: String, testMethod: String, device: DeviceConfig, variant: VariantCombo, counter: Int) -> URL
    func save(image: UIImage, to url: URL) throws
    func load(from url: URL) throws -> UIImage
    func exists(at url: URL) -> Bool
    func allSnapshotURLs() -> [URL]
}

// MARK: - Errors

public enum GoldenFileError: Error {
    case fileNotFound(URL)
    case invalidImageData(URL)
    case saveFailed(URL, Error)
}

// MARK: - Implementation

public final class GoldenFileManager: GoldenFileManaging {

    private let snapshotsBaseDir: URL

    public init(snapshotsBaseDir: URL) {
        self.snapshotsBaseDir = snapshotsBaseDir
    }

    public func goldenURL(
        testClass: String,
        testMethod: String,
        device: DeviceConfig,
        variant: VariantCombo,
        counter: Int
    ) -> URL {
        let counterSuffix = counter > 0 ? "_\(counter)" : ""
        let filename = "\(testMethod)_\(device.filenameSuffix)_\(variant.filenameSuffix)\(counterSuffix).png"
        return snapshotsBaseDir
            .appendingPathComponent(testClass)
            .appendingPathComponent(filename)
    }

    public func save(image: UIImage, to url: URL) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = image.pngData() else {
            throw GoldenFileError.saveFailed(url, NSError(domain: "SnareShot", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to generate PNG data"
            ]))
        }
        do {
            try data.write(to: url)
        } catch {
            throw GoldenFileError.saveFailed(url, error)
        }
    }

    public func load(from url: URL) throws -> UIImage {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GoldenFileError.fileNotFound(url)
        }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            throw GoldenFileError.invalidImageData(url)
        }
        return image
    }

    public func exists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }

    public func allSnapshotURLs() -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: snapshotsBaseDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var urls: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            if url.pathExtension == "png" {
                urls.append(url)
            }
        }
        return urls.sorted { $0.path < $1.path }
    }
}
