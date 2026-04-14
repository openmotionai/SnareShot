import Foundation

public enum GalleryReportGenerator {

    private static let knownDevices: [String] = [
        "iPhone15ProMax",
        "iPhone15Pro",
        "iPhone15",
        "iPhoneSE3",
        "iPadPro12",
        "iPadPro11"
    ]

    private struct SnapshotEntry {
        let name: String
        let device: String
        let variant: String
        let testClass: String
        let base64: String
    }

    @discardableResult
    public static func generate(snapshotsDir: URL) -> URL {
        let entries = collectEntries(in: snapshotsDir)
        let html = buildHTML(entries: entries)
        let outputURL = snapshotsDir.appendingPathComponent("gallery.html")
        try? html.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }

    // MARK: - Collection

    private static func collectEntries(in dir: URL) -> [SnapshotEntry] {
        var entries: [SnapshotEntry] = []
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return entries
        }
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "png" else { continue }
            let testClass = fileURL.deletingLastPathComponent().lastPathComponent
            let filename = fileURL.deletingPathExtension().lastPathComponent
            let (name, device, variant) = parseFilename(filename)
            guard let data = try? Data(contentsOf: fileURL) else { continue }
            let base64 = data.base64EncodedString()
            entries.append(SnapshotEntry(
                name: name,
                device: device,
                variant: variant,
                testClass: testClass,
                base64: base64
            ))
        }
        return entries
    }

    // MARK: - Filename Parsing

    private static func parseFilename(_ filename: String) -> (name: String, device: String, variant: String) {
        let segments = filename.components(separatedBy: "_")
        guard !segments.isEmpty else {
            return (filename, "", "")
        }
        let name = segments[0]
        var device = ""
        var variantSegments: [String] = []

        // Find the first segment that matches a known device name
        var deviceFound = false
        for (index, segment) in segments.enumerated() {
            if index == 0 { continue }
            if !deviceFound {
                // Try to match known devices by comparing accumulated segments
                let accumulated = segments[1...index].joined(separator: "_")
                if knownDevices.contains(accumulated) {
                    device = accumulated
                    deviceFound = true
                    variantSegments = Array(segments[(index + 1)...])
                    break
                }
            }
        }

        if !deviceFound {
            // Fallback: second segment is device, rest is variant
            if segments.count > 1 { device = segments[1] }
            if segments.count > 2 { variantSegments = Array(segments[2...]) }
        }

        let variant = variantSegments.joined(separator: "_")
        return (name, device, variant)
    }

    // MARK: - HTML Generation

    private static func buildHTML(entries: [SnapshotEntry]) -> String {
        let count = entries.count
        let devices = Set(entries.map { $0.device }).sorted().joined(separator: ", ")
        let dateStr = ISO8601DateFormatter().string(from: Date())

        let cards = entries.map { cardHTML(for: $0) }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SnareShot Gallery</title>
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            background: #0d0d1a;
            color: #e8e8f0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            padding: 24px;
          }
          header {
            text-align: center;
            margin-bottom: 32px;
          }
          header h1 {
            font-size: 2rem;
            font-weight: 700;
            letter-spacing: -0.5px;
            color: #ffffff;
          }
          header p {
            margin-top: 8px;
            font-size: 0.875rem;
            color: #9090b0;
          }
          .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
            gap: 20px;
          }
          .card {
            background: #1a1a2e;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 16px rgba(0,0,0,0.4);
            display: flex;
            flex-direction: column;
          }
          .card img {
            width: 100%;
            display: block;
            object-fit: contain;
            background: #0d0d1a;
          }
          .card-body {
            padding: 12px;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 6px;
          }
          .screen-name {
            font-size: 0.875rem;
            font-weight: 600;
            color: #e8e8f0;
            word-break: break-word;
          }
          .test-class {
            font-size: 0.75rem;
            color: #9090b0;
          }
          .badges {
            display: flex;
            flex-wrap: wrap;
            gap: 4px;
            margin-top: 4px;
          }
          .badge {
            font-size: 0.7rem;
            font-weight: 600;
            padding: 2px 8px;
            border-radius: 100px;
          }
          .badge-device {
            background: #2d1b69;
            color: #b794f6;
          }
          .badge-variant {
            background: #0d4b4b;
            color: #5ec4c4;
          }
        </style>
        </head>
        <body>
        <header>
          <h1>SnareShot Gallery</h1>
          <p>\(count) screens &bull; \(devices) &bull; \(dateStr)</p>
        </header>
        <main class="grid">
        \(cards)
        </main>
        </body>
        </html>
        """
    }

    private static func cardHTML(for entry: SnapshotEntry) -> String {
        let variantBadge = entry.variant.isEmpty
            ? ""
            : "<span class=\"badge badge-variant\">\(htmlEscape(entry.variant))</span>"
        let deviceBadge = entry.device.isEmpty
            ? ""
            : "<span class=\"badge badge-device\">\(htmlEscape(entry.device))</span>"
        return """
          <div class="card">
            <img src="data:image/png;base64,\(entry.base64)" alt="\(htmlEscape(entry.name))">
            <div class="card-body">
              <div class="screen-name">\(htmlEscape(entry.name))</div>
              <div class="test-class">\(htmlEscape(entry.testClass))</div>
              <div class="badges">
                \(deviceBadge)
                \(variantBadge)
              </div>
            </div>
          </div>
        """
    }

    private static func htmlEscape(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
