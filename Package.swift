// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnareShot",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SnareShot",
            targets: ["SnareShot"]
        )
    ],
    targets: [
        .target(
            name: "SnareShot",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("XCTest", .when(platforms: [.iOS]))
            ]
        ),
        .testTarget(
            name: "SnareShotTests",
            dependencies: ["SnareShot"]
        )
    ]
)
