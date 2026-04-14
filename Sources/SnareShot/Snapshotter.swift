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

        // UIWindow must be attached to a UIWindowScene for drawHierarchy to
        // render content (iOS 13+). Grab the active scene from the test host app.
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: CGRect(origin: .zero, size: screenSize))
        }

        window.frame = CGRect(origin: .zero, size: screenSize)
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
        for _ in 0..<3 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
        }

        // UIImageView sets layer.contents lazily via the display pipeline.
        // layer.render(in:) captures the layer tree directly, bypassing that
        // pipeline, so images from asset catalogs appear blank. Fix: walk the
        // view tree and explicitly commit every UIImageView's content to its
        // layer before rendering.
        Self.commitImageContent(in: viewController.view)

        let renderer = UIGraphicsImageRenderer(size: screenSize)
        let image = renderer.image { ctx in
            viewController.view.layer.render(in: ctx.cgContext)
        }

        window.isHidden = true
        window.rootViewController = nil

        return image
    }

    // MARK: - Image content commit

    /// Recursively walks the view tree and explicitly sets layer.contents for
    /// every UIImageView. UIKit normally does this lazily through the display
    /// pipeline, but layer.render(in:) bypasses that pipeline, leaving image
    /// layers empty. This forces the content to be present before capture.
    private static func commitImageContent(in view: UIView) {
        if let imageView = view as? UIImageView, let image = imageView.image {
            // Force the image into the layer's backing store. Setting
            // layer.contents directly with the CGImage makes it available
            // for layer.render(in:) without waiting for the display pipeline.
            if imageView.layer.contents == nil {
                imageView.layer.contents = image.cgImage
            }
        }

        for subview in view.subviews {
            commitImageContent(in: subview)
        }
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
