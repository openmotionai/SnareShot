import UIKit
import SwiftUI

public enum SnapshotTarget {
    case swiftUI(AnyView)
    case viewController(UIViewController)
    case view(UIView)
}
