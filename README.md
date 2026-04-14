# SnareShot

iOS screenshot testing library. Record golden images, verify on every test run, browse results in an HTML gallery.

Supports SwiftUI and UIKit. No XCTestCase subclassing required.

## Install

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/openmotionai/SnareShot", from: "1.0.0")
]
```

Add to your test target:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: ["SnareShot"]
)
```

## Usage

### Simple

```swift
import XCTest
import SnareShot

final class MyTests: XCTestCase {
    func testWelcomeScreen() {
        assertSnapshot(of: WelcomeView())
    }
}
```

This snapshots in light + dark mode on iPhone 15 Pro by default.

### Builder API

```swift
SnareShot.verify(LoginView())
    .devices(.iPhone15Pro, .iPhoneSE3)
    .variants(.lightDark, .dynamicType([.large, .accessibilityExtraExtraLarge]))
    .tolerance(0.01)
    .run()
```

### UIKit

```swift
let vc = SettingsViewController()
assertSnapshot(of: vc)
```

## Record

```bash
SNARESHOT_RECORD=1 xcodebuild test \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

Commit the golden images in `__Snapshots__/` to git.

## Verify

```bash
xcodebuild test -scheme MyApp -destination '...'
```

Mismatches produce 3-panel diff images in `__Failures__/`.

## Reports

- **Gallery:** `__Snapshots__/gallery.html` -- browsable catalog of all screens (always generated)
- **Failures:** `__Failures__/report.html` -- visual diff report (generated on mismatches)

## Device Presets

- `.iPhoneSE3` (375x667 @2x)
- `.iPhone15` (390x844 @3x)
- `.iPhone15Pro` (393x852 @3x)
- `.iPhone15ProMax` (430x932 @3x)
- `.iPadPro11` (834x1194 @2x)
- `.iPadPro12` (1024x1366 @2x)

## Variants

- `.light`, `.dark`, `.lightDark`
- `.dynamicType([.large, .accessibilityLarge, ...])`
- `.portrait`, `.landscape`, `.orientations`

Variants are combined as a Cartesian product. `.lightDark` + `.orientations` = 4 snapshots.

## License

MIT
