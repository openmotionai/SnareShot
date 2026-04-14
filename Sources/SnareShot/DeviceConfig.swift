import UIKit

public enum DeviceConfig: CaseIterable, Sendable {
    case iPhoneSE3
    case iPhone15
    case iPhone15Pro
    case iPhone15ProMax
    case iPadPro11
    case iPadPro12

    public var screenSize: CGSize {
        switch self {
        case .iPhoneSE3:       return CGSize(width: 375, height: 667)
        case .iPhone15:        return CGSize(width: 390, height: 844)
        case .iPhone15Pro:     return CGSize(width: 393, height: 852)
        case .iPhone15ProMax:  return CGSize(width: 430, height: 932)
        case .iPadPro11:       return CGSize(width: 834, height: 1194)
        case .iPadPro12:       return CGSize(width: 1024, height: 1366)
        }
    }

    public var scale: CGFloat {
        switch self {
        case .iPhoneSE3:       return 2
        case .iPhone15:        return 3
        case .iPhone15Pro:     return 3
        case .iPhone15ProMax:  return 3
        case .iPadPro11:       return 2
        case .iPadPro12:       return 2
        }
    }

    public var safeAreaInsets: UIEdgeInsets {
        switch self {
        case .iPhoneSE3:
            return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        case .iPhone15, .iPhone15Pro:
            return UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        case .iPhone15ProMax:
            return UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        case .iPadPro11, .iPadPro12:
            return UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0)
        }
    }

    public var displayName: String {
        return filenameSuffix
    }

    public var filenameSuffix: String {
        switch self {
        case .iPhoneSE3:       return "iPhoneSE3"
        case .iPhone15:        return "iPhone15"
        case .iPhone15Pro:     return "iPhone15Pro"
        case .iPhone15ProMax:  return "iPhone15ProMax"
        case .iPadPro11:       return "iPadPro11"
        case .iPadPro12:       return "iPadPro12"
        }
    }
}
