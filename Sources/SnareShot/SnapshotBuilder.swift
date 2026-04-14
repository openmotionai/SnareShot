import UIKit
import XCTest

// MARK: - Config

public struct SnapshotConfig {
    public var devices: [DeviceConfig]
    public var variants: [Variant]
    public var tolerance: Double

    public static let defaultConfig = SnapshotConfig(
        devices: [.iPhone15Pro],
        variants: [.lightDark],
        tolerance: 0.0
    )
}

// MARK: - Builder

public struct SnapshotBuilder {

    let target: SnapshotTarget
    private(set) var resolvedConfig: SnapshotConfig

    public init(target: SnapshotTarget, config: SnapshotConfig) {
        self.target = target
        self.resolvedConfig = config
    }

    public func devices(_ devices: DeviceConfig...) -> SnapshotBuilder {
        var copy = self
        copy.resolvedConfig.devices = devices
        return copy
    }

    public func variants(_ variants: Variant...) -> SnapshotBuilder {
        var copy = self
        copy.resolvedConfig.variants = variants
        return copy
    }

    public func tolerance(_ value: Double) -> SnapshotBuilder {
        var copy = self
        copy.resolvedConfig.tolerance = value
        return copy
    }

    public func run(
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        _ = SnareShot._ensureObserver

        let testClass = testClassName(from: file)
        let testMethod = testMethodName(from: function)
        let isRecording = SnapshotBuilder.isRecordMode

        let snapshotter = Snapshotter()
        let snapshotsDir = snapshotsDirectory(from: file)
        let fileManager = GoldenFileManager(snapshotsBaseDir: snapshotsDir)
        let diffEngine = DiffEngine()
        let matrix = VariantMatrix(variants: resolvedConfig.variants)
        let combos = matrix.expand()

        let counter = SnareShotState.shared.nextCounter(for: "\(testClass).\(testMethod)")

        for device in resolvedConfig.devices {
            for combo in combos {
                let url = fileManager.goldenURL(
                    testClass: testClass,
                    testMethod: testMethod,
                    device: device,
                    variant: combo,
                    counter: counter
                )

                let actual = snapshotter.render(target: target, device: device, variant: combo)

                if isRecording {
                    do {
                        try fileManager.save(image: actual, to: url)
                        SnareShotState.shared.recordSnapshot(url: url, testClass: testClass)
                    } catch {
                        XCTFail("SnareShot: Failed to save golden image: \(error)", file: file, line: line)
                    }
                } else {
                    guard fileManager.exists(at: url) else {
                        XCTFail(
                            "SnareShot: Golden image not found at \(url.path). Run with SNARESHOT_RECORD=1 to record.",
                            file: file,
                            line: line
                        )
                        continue
                    }

                    do {
                        let expected = try fileManager.load(from: url)
                        let result = diffEngine.compare(
                            expected: expected,
                            actual: actual,
                            tolerance: resolvedConfig.tolerance
                        )

                        switch result {
                        case .match:
                            SnareShotState.shared.recordSnapshot(url: url, testClass: testClass)
                        case .mismatch(let pct, _, let composite):
                            let failureDir = snapshotsDir
                                .deletingLastPathComponent()
                                .appendingPathComponent("__Failures__")
                                .appendingPathComponent(testClass)
                            let diffURL = failureDir.appendingPathComponent(
                                url.deletingPathExtension().lastPathComponent + "_diff.png"
                            )
                            try? fileManager.save(image: composite, to: diffURL)
                            SnareShotState.shared.recordFailure(
                                testClass: testClass,
                                snapshotName: url.deletingPathExtension().lastPathComponent,
                                diffPercentage: pct,
                                diffURL: diffURL
                            )
                            XCTFail(
                                "SnareShot: Snapshot mismatch (\(String(format: "%.1f%%", pct * 100)) diff). Diff saved to \(diffURL.path)",
                                file: file,
                                line: line
                            )
                        }
                    } catch {
                        XCTFail("SnareShot: Failed to load golden image: \(error)", file: file, line: line)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    public static var isRecordMode: Bool {
        ProcessInfo.processInfo.environment["SNARESHOT_RECORD"] == "1"
    }

    private func testClassName(from file: StaticString) -> String {
        let path = "\(file)"
        let filename = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        return filename
    }

    private func testMethodName(from function: String) -> String {
        return function.replacingOccurrences(of: "()", with: "")
    }

    private func snapshotsDirectory(from file: StaticString) -> URL {
        let path = "\(file)"
        let testFileDir = URL(fileURLWithPath: path).deletingLastPathComponent()
        return testFileDir.appendingPathComponent("__Snapshots__")
    }
}

// MARK: - Shared State

public final class SnareShotState {
    public static let shared = SnareShotState()

    private var counters: [String: Int] = [:]
    private(set) var snapshotURLs: [(url: URL, testClass: String)] = []
    private(set) var failures: [(testClass: String, snapshotName: String, diffPercentage: Double, diffURL: URL)] = []

    private init() {}

    func nextCounter(for key: String) -> Int {
        let current = counters[key, default: 0]
        counters[key] = current + 1
        return current
    }

    func recordSnapshot(url: URL, testClass: String) {
        snapshotURLs.append((url: url, testClass: testClass))
    }

    func recordFailure(testClass: String, snapshotName: String, diffPercentage: Double, diffURL: URL) {
        failures.append((
            testClass: testClass,
            snapshotName: snapshotName,
            diffPercentage: diffPercentage,
            diffURL: diffURL
        ))
    }

    func reset() {
        counters.removeAll()
        snapshotURLs.removeAll()
        failures.removeAll()
    }
}
