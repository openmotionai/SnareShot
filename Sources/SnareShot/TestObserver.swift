import Foundation
import XCTest

public final class SnareShotTestObserver: NSObject, XCTestObservation {

    private static var isRegistered = false

    public static func register() {
        guard !isRegistered else { return }
        isRegistered = true
        let observer = SnareShotTestObserver()
        XCTestObservationCenter.shared.addTestObserver(observer)
    }

    public func testBundleWillStart(_ testBundle: Bundle) {
        SnareShotState.shared.reset()
    }

    public func testBundleDidFinish(_ testBundle: Bundle) {
        let state = SnareShotState.shared

        // Generate gallery report if any snapshots were recorded
        if !state.snapshotURLs.isEmpty {
            if let firstURL = state.snapshotURLs.first?.url {
                let snapshotsDir = firstURL
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                GalleryReportGenerator.generate(snapshotsDir: snapshotsDir)
            }
        }

        // Generate failure report if any failures occurred
        if !state.failures.isEmpty {
            let failureEntries = state.failures.map { failure in
                FailureReportGenerator.FailureEntry(
                    testClass: failure.testClass,
                    snapshotName: failure.snapshotName,
                    diffPercentage: failure.diffPercentage,
                    diffImageURL: failure.diffURL
                )
            }

            if let firstFailure = state.failures.first {
                let failuresDir = firstFailure.diffURL
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                FailureReportGenerator.generate(failures: failureEntries, outputDir: failuresDir)
            }
        }
    }
}
