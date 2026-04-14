import UIKit
import SwiftUI

public enum SnareShot {
    public static let version = "0.1.0"

    /// Entry point for the builder API.
    public static func verify<V: View>(_ view: V) -> SnapshotBuilder {
        return SnapshotBuilder(
            target: .swiftUI(AnyView(view)),
            config: .defaultConfig
        )
    }

    public static func verify(_ viewController: UIViewController) -> SnapshotBuilder {
        return SnapshotBuilder(
            target: .viewController(viewController),
            config: .defaultConfig
        )
    }

    public static func verify(_ view: UIView) -> SnapshotBuilder {
        return SnapshotBuilder(
            target: .view(view),
            config: .defaultConfig
        )
    }

    // Observer registration (will be wired in Task 10)
    static let _ensureObserver: Void = ()
}

// MARK: - Free function API

/// Snapshot a SwiftUI view with default config (iPhone 15 Pro, light + dark).
public func assertSnapshot<V: View>(
    of view: V,
    file: StaticString = #filePath,
    function: String = #function,
    line: UInt = #line
) {
    _ = SnareShot._ensureObserver
    SnapshotBuilder(
        target: .swiftUI(AnyView(view)),
        config: .defaultConfig
    ).run(file: file, function: function, line: line)
}

/// Snapshot a UIViewController with default config.
public func assertSnapshot(
    of viewController: UIViewController,
    file: StaticString = #filePath,
    function: String = #function,
    line: UInt = #line
) {
    _ = SnareShot._ensureObserver
    SnapshotBuilder(
        target: .viewController(viewController),
        config: .defaultConfig
    ).run(file: file, function: function, line: line)
}

/// Snapshot a UIView with default config.
public func assertSnapshot(
    of view: UIView,
    file: StaticString = #filePath,
    function: String = #function,
    line: UInt = #line
) {
    _ = SnareShot._ensureObserver
    SnapshotBuilder(
        target: .view(view),
        config: .defaultConfig
    ).run(file: file, function: function, line: line)
}
