<p align="center">
  <img src="https://openmotion-public-images.s3.amazonaws.com/snareshot/snareshot-logo.svg" alt="SnareShot" width="280" />
</p>

<p align="center">
  <strong>Screenshot testing for iOS.</strong><br>
  Record. Verify. Browse.
</p>

<p align="center">
  <a href="https://github.com/openmotionai/SnareShot/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-9D4EDD.svg" alt="MIT License" /></a>
  <img src="https://img.shields.io/badge/platform-iOS_16+-0d0d1a.svg" alt="iOS 16+" />
  <img src="https://img.shields.io/badge/Swift-5.9+-0d0d1a.svg" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/SPM-compatible-9D4EDD.svg" alt="SPM Compatible" />
</p>

---

SnareShot captures pixel-accurate screenshots of your SwiftUI and UIKit views, saves them as golden images, and verifies them on every test run. When something changes, you get a 3-panel diff and a browsable HTML report showing exactly what broke.

No device farm. No XCTestCase subclassing. One line of code.

```swift
func testWelcomeScreen() {
    assertSnapshot(of: WelcomeView())
}
```

## Why SnareShot

| | SnareShot | swift-snapshot-testing | iOSSnapshotTestCase |
|---|:---:|:---:|:---:|
| SwiftUI + UIKit | Yes | Yes | UIKit only |
| Auto light/dark mode | Yes | Manual | No |
| Auto Dynamic Type | Yes | Manual | No |
| Device presets | 6 built-in | None | None |
| HTML gallery report | Yes | No | No |
| HTML failure diffs | Yes | No | No |
| No subclassing | Yes | Yes | No |
| One-line API | Yes | Yes | No |

## Install

**Swift Package Manager**

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/openmotionai/SnareShot", from: "1.0.0")
]
```

```swift
// Your test target
.testTarget(
    name: "MyAppTests",
    dependencies: ["SnareShot"]
)
```

Or in Xcode: **File > Add Package Dependencies** and paste `https://github.com/openmotionai/SnareShot`.

## Quick Start

### 1. Write a test

```swift
import XCTest
import SnareShot

final class OnboardingTests: XCTestCase {

    func testWelcomeScreen() {
        // One screenshot: iPhone 15 Pro, light mode, portrait
        assertSnapshot(of: WelcomeView())
    }

    func testLoginScreen() {
        // Explicit config: 2 devices x 2 schemes x 2 type sizes = 8 snapshots
        SnareShot.verify(LoginView(email: "user@example.com"))
            .devices(.iPhone15Pro, .iPhoneSE3)
            .variants(.lightDark, .dynamicType([.large, .accessibilityExtraExtraLarge]))
            .run()
    }

    func testSettingsViewController() {
        // UIKit works too
        let vc = SettingsViewController()
        assertSnapshot(of: vc)
    }
}
```

### 2. Record golden images

```bash
SNARESHOT_RECORD=1 xcodebuild test \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

Golden PNGs are saved to `__Snapshots__/` next to your test files. Commit them to git -- they are the source of truth.

### 3. Verify on every test run

```bash
xcodebuild test -scheme MyApp -destination '...'
```

If a snapshot changes, the test fails with a clear message and a 3-panel diff image (expected | actual | diff) saved to `__Failures__/`.

### 4. Browse the reports

Every test run generates two HTML reports:

- **`__Snapshots__/gallery.html`** -- a browsable dark-themed catalog of every screen in your app. Always generated.
- **`__Failures__/report.html`** -- visual diff report with percentage breakdowns. Only generated when mismatches are detected.

Both are self-contained single HTML files with inline images. Open locally or attach to CI artifacts.

## API Reference

### Free Function (simplest)

```swift
assertSnapshot(of: MyView())          // SwiftUI
assertSnapshot(of: myViewController)  // UIViewController
assertSnapshot(of: myView)            // UIView
```

Uses defaults: iPhone 15 Pro, light mode, 0% tolerance. One screenshot per call.

### Builder (full control)

```swift
SnareShot.verify(MyView())
    .devices(.iPhone15Pro, .iPhoneSE3, .iPadPro12)
    .variants(.lightDark, .dynamicType([.large, .accessibilityLarge]), .orientations)
    .tolerance(0.01)
    .run()
```

Chain any combination of:

| Method | Description | Default |
|---|---|---|
| `.devices(...)` | Device screen sizes to render | `.iPhone15Pro` |
| `.variants(...)` | Color scheme, Dynamic Type, orientation | `.light` |
| `.tolerance(...)` | Per-pixel color tolerance (0.0 - 1.0) | `0.0` (exact) |

## Device Presets

| Preset | Screen Size | Scale |
|---|---|---|
| `.iPhoneSE3` | 375 x 667 | @2x |
| `.iPhone15` | 390 x 844 | @3x |
| `.iPhone15Pro` | 393 x 852 | @3x |
| `.iPhone15ProMax` | 430 x 932 | @3x |
| `.iPadPro11` | 834 x 1194 | @2x |
| `.iPadPro12` | 1024 x 1366 | @2x |

## Variants

Variants are combined as a Cartesian product. Each unique combination produces a separate golden image.

```swift
// 2 color schemes x 2 type sizes x 2 orientations = 8 snapshots
.variants(.lightDark, .dynamicType([.large, .accessibilityLarge]), .orientations)
```

| Variant | Expands To |
|---|---|
| `.light` | Light mode only |
| `.dark` | Dark mode only |
| `.lightDark` | Light + dark |
| `.dynamicType([...])` | One snapshot per size category |
| `.portrait` | Portrait only |
| `.landscape` | Landscape only |
| `.orientations` | Portrait + landscape |

## CI Integration

### GitHub Actions

```yaml
- name: Snapshot tests
  run: |
    xcodebuild test \
      -scheme MyApp \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

- name: Upload failure report
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: snapshot-failures
    path: |
      **/\__Failures__/report.html
      **/\__Failures__/**/*.png
```

## How It Works

1. Your test calls `assertSnapshot(of:)` or `SnareShot.verify(...).run()`
2. SnareShot creates an off-screen `UIWindow`, wraps your view in a `UIHostingController` (SwiftUI) or uses your `UIViewController` directly, applies trait overrides for the current variant, and renders via `UIGraphicsImageRenderer`
3. In **record mode** (`SNARESHOT_RECORD=1`): saves the rendered image as a golden PNG
4. In **verify mode** (default): loads the golden PNG, compares pixel-by-pixel, and generates a 3-panel diff composite on mismatch
5. After all tests finish, an `XCTestObservation` hook generates the HTML gallery and failure reports

## Requirements

- iOS 16+
- Swift 5.9+
- Xcode 15+
- Runs in the iOS Simulator (uses real UIKit/SwiftUI rendering)

## License

MIT. See [LICENSE](LICENSE).

---

<p align="center">
  Built by <a href="https://github.com/openmotionai">OpenMotion AI</a>
</p>
