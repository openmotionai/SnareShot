import UIKit

// MARK: - Variant

public enum Variant: Sendable {
    case light
    case dark
    case lightDark
    case dynamicType([UIContentSizeCategory])
    case portrait
    case landscape
    case orientations
}

// MARK: - Orientation

public enum SnapshotOrientation: String, Sendable {
    case portrait
    case landscape
}

// MARK: - ColorScheme

public enum SnapshotColorScheme: String, Sendable {
    case light
    case dark

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - VariantCombo

public struct VariantCombo: Sendable {
    public let colorScheme: SnapshotColorScheme
    public let contentSizeCategory: UIContentSizeCategory
    public let orientation: SnapshotOrientation

    public init(
        colorScheme: SnapshotColorScheme = .light,
        contentSizeCategory: UIContentSizeCategory = .large,
        orientation: SnapshotOrientation = .portrait
    ) {
        self.colorScheme = colorScheme
        self.contentSizeCategory = contentSizeCategory
        self.orientation = orientation
    }

    public var filenameSuffix: String {
        let sizeName = contentSizeCategoryName(contentSizeCategory)
        return "\(colorScheme.rawValue)_\(sizeName)_\(orientation.rawValue)"
    }

    public var traitCollection: UITraitCollection {
        return UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: colorScheme.userInterfaceStyle),
            UITraitCollection(preferredContentSizeCategory: contentSizeCategory),
        ])
    }

    private func contentSizeCategoryName(_ category: UIContentSizeCategory) -> String {
        switch category {
        case .extraSmall:                          return "extraSmall"
        case .small:                               return "small"
        case .medium:                              return "medium"
        case .large:                               return "large"
        case .extraLarge:                          return "extraLarge"
        case .extraExtraLarge:                     return "extraExtraLarge"
        case .extraExtraExtraLarge:                return "extraExtraExtraLarge"
        case .accessibilityMedium:                 return "accessibilityMedium"
        case .accessibilityLarge:                  return "accessibilityLarge"
        case .accessibilityExtraLarge:             return "accessibilityExtraLarge"
        case .accessibilityExtraExtraLarge:        return "accessibilityExtraExtraLarge"
        case .accessibilityExtraExtraExtraLarge:   return "accessibilityExtraExtraExtraLarge"
        default:                                   return category.rawValue
        }
    }
}

// MARK: - VariantMatrix

public struct VariantMatrix: Sendable {
    public let variants: [Variant]

    public init(variants: [Variant]) {
        self.variants = variants
    }

    public func expand() -> [VariantCombo] {
        var colorSchemes: [SnapshotColorScheme] = []
        var sizeCategories: [UIContentSizeCategory] = []
        var orientations: [SnapshotOrientation] = []

        for variant in variants {
            switch variant {
            case .light:
                colorSchemes.append(.light)
            case .dark:
                colorSchemes.append(.dark)
            case .lightDark:
                colorSchemes.append(contentsOf: [.light, .dark])
            case .dynamicType(let categories):
                sizeCategories.append(contentsOf: categories)
            case .portrait:
                orientations.append(.portrait)
            case .landscape:
                orientations.append(.landscape)
            case .orientations:
                orientations.append(contentsOf: [.portrait, .landscape])
            }
        }

        // Defaults when an axis is not specified
        if colorSchemes.isEmpty { colorSchemes = [.light] }
        if sizeCategories.isEmpty { sizeCategories = [.large] }
        if orientations.isEmpty { orientations = [.portrait] }

        // Cartesian product
        var combos: [VariantCombo] = []
        for scheme in colorSchemes {
            for size in sizeCategories {
                for orientation in orientations {
                    combos.append(VariantCombo(
                        colorScheme: scheme,
                        contentSizeCategory: size,
                        orientation: orientation
                    ))
                }
            }
        }
        return combos
    }
}
