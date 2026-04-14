import Foundation
import UIKit

public enum FailureReportGenerator {

    public struct FailureEntry {
        public let testClass: String
        public let snapshotName: String
        public let diffPercentage: Double
        public let diffImageURL: URL

        public init(testClass: String, snapshotName: String, diffPercentage: Double, diffImageURL: URL) {
            self.testClass = testClass
            self.snapshotName = snapshotName
            self.diffPercentage = diffPercentage
            self.diffImageURL = diffImageURL
        }
    }

    @discardableResult
    public static func generate(failures: [FailureEntry], outputDir: URL) -> URL {
        let grouped = Dictionary(grouping: failures, by: { $0.testClass })
        let sortedClasses = grouped.keys.sorted()

        let dateString = ISO8601DateFormatter().string(from: Date())
        let count = failures.count

        var sectionsHTML = ""
        for testClass in sortedClasses {
            let entries = grouped[testClass] ?? []
            var cardsHTML = ""
            for entry in entries {
                let base64 = (try? Data(contentsOf: entry.diffImageURL))
                    .map { "data:image/png;base64," + $0.base64EncodedString() } ?? ""
                let pctString = String(format: "%.1f%%", entry.diffPercentage * 100)
                cardsHTML += """
                <div class="card">
                    <img src="\(base64)" alt="diff for \(entry.snapshotName)" />
                    <div class="card-info">
                        <div class="snapshot-name">\(entry.snapshotName)</div>
                        <div class="diff-pct">\(pctString) pixels differ</div>
                    </div>
                </div>
                """
            }
            sectionsHTML += """
            <section>
                <h2>\(testClass)</h2>
                <div class="grid">\(cardsHTML)</div>
            </section>
            """
        }

        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>SnareShot Failures</title>
            <style>
                body {
                    margin: 0;
                    padding: 24px;
                    background: #0d0d1a;
                    color: #e0e0f0;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
                }
                h1 {
                    color: #ff6b6b;
                    font-size: 2rem;
                    margin-bottom: 4px;
                }
                .meta {
                    color: #888;
                    font-size: 0.9rem;
                    margin-bottom: 32px;
                }
                h2 {
                    color: #c0c0e0;
                    font-size: 1.3rem;
                    border-bottom: 1px solid #2a2a4a;
                    padding-bottom: 8px;
                    margin-top: 32px;
                }
                .grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
                    gap: 20px;
                    margin-top: 16px;
                }
                .card {
                    background: #1a1a2e;
                    border: 1px solid #3d1f1f;
                    border-radius: 8px;
                    overflow: hidden;
                }
                .card img {
                    width: 100%;
                    display: block;
                }
                .card-info {
                    padding: 12px 16px;
                }
                .snapshot-name {
                    font-size: 0.85rem;
                    color: #b0b0d0;
                    word-break: break-all;
                    margin-bottom: 6px;
                }
                .diff-pct {
                    font-size: 0.9rem;
                    color: #ff6b6b;
                    font-weight: 600;
                }
            </style>
        </head>
        <body>
            <h1>SnareShot Failures</h1>
            <p class="meta">\(count) failure(s) -- \(dateString)</p>
            \(sectionsHTML)
        </body>
        </html>
        """

        let outputURL = outputDir.appendingPathComponent("report.html")
        try? html.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }
}
