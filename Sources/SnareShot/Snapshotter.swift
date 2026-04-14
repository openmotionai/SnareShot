import UIKit
import SwiftUI

// MARK: - Protocol

public protocol SnapshotRendering {
    func render(target: SnapshotTarget, device: DeviceConfig, variant: VariantCombo) -> UIImage
}

// MARK: - Implementation

public final class Snapshotter: SnapshotRendering {

    public init() {}

    public func render(target: SnapshotTarget, device: DeviceConfig, variant: VariantCombo) -> UIImage {
        let viewController = makeViewController(from: target)
        let screenSize = effectiveScreenSize(device: device, orientation: variant.orientation)

        // Set up window with the correct size and traits
        let window = UIWindow(frame: CGRect(origin: .zero, size: screenSize))
        window.overrideUserInterfaceStyle = variant.colorScheme.userInterfaceStyle

        // Set the root VC and configure traits before triggering lifecycle
        window.rootViewController = viewController
        viewController.overrideUserInterfaceStyle = variant.colorScheme.userInterfaceStyle
        viewController.additionalSafeAreaInsets = device.safeAreaInsets

        // Make window visible -- this triggers viewDidLoad
        window.makeKeyAndVisible()

        // Explicitly size the view to match the device
        viewController.view.frame = CGRect(origin: .zero, size: screenSize)

        // Trigger the full appearance lifecycle (viewWillAppear / viewDidAppear)
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()

        // Force layout
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()

        // Pump the run loop to let UIKit and SwiftUI settle.
        // Multiple passes handle async layout, CALayer updates, and deferred blocks.
        for _ in 0..<3 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
        }

        let renderer = UIGraphicsImageRenderer(size: screenSize)
        let image = renderer.image { _ in
            window.drawHierarchy(in: CGRect(origin: .zero, size: screenSize), afterScreenUpdates: true)
        }

        window.isHidden = true
        window.rootViewController = nil

        return image
    }

    // MARK: - Helpers

    private func makeViewController(from target: SnapshotTarget) -> UIViewController {
        switch target {
        case .swiftUI(let anyView):
            return UIHostingController(rootView: anyView)
        case .viewController(let vc):
            return vc
        case .view(let view):
            let vc = UIViewController()
            vc.view.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: vc.view.topAnchor),
                view.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            ])
            return vc
        }
    }

    private func effectiveScreenSize(device: DeviceConfig, orientation: SnapshotOrientation) -> CGSize {
        let size = device.screenSize
        switch orientation {
        case .portrait:
            return size
        case .landscape:
            return CGSize(width: size.height, height: size.width)
        }
    }
}
