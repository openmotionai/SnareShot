import XCTest
import UIKit
@testable import SnareShot

final class VariantTests: XCTestCase {

    // MARK: - VariantCombo filename

    func testVariantComboFilename_lightLargePortrait() {
        let combo = VariantCombo(
            colorScheme: .light,
            contentSizeCategory: .large,
            orientation: .portrait
        )
        XCTAssertEqual(combo.filenameSuffix, "light_large_portrait")
    }

    func testVariantComboFilename_darkA11yXLLandscape() {
        let combo = VariantCombo(
            colorScheme: .dark,
            contentSizeCategory: .accessibilityExtraLarge,
            orientation: .landscape
        )
        XCTAssertEqual(combo.filenameSuffix, "dark_accessibilityExtraLarge_landscape")
    }

    // MARK: - VariantMatrix expansion

    func testLightDarkExpands() {
        let matrix = VariantMatrix(variants: [.lightDark])
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 2)
        XCTAssertEqual(combos[0].colorScheme, .light)
        XCTAssertEqual(combos[1].colorScheme, .dark)
    }

    func testSingleLightVariant() {
        let matrix = VariantMatrix(variants: [.light])
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 1)
        XCTAssertEqual(combos[0].colorScheme, .light)
    }

    func testDynamicTypeExpands() {
        let matrix = VariantMatrix(variants: [.dynamicType([.large, .accessibilityLarge])])
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 2)
        XCTAssertEqual(combos[0].contentSizeCategory, .large)
        XCTAssertEqual(combos[1].contentSizeCategory, .accessibilityLarge)
    }

    func testOrientationsExpands() {
        let matrix = VariantMatrix(variants: [.orientations])
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 2)
        XCTAssertEqual(combos[0].orientation, .portrait)
        XCTAssertEqual(combos[1].orientation, .landscape)
    }

    func testCartesianProduct_lightDark_x_dynamicType() {
        let matrix = VariantMatrix(variants: [
            .lightDark,
            .dynamicType([.large, .accessibilityLarge])
        ])
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 4)

        let suffixes = combos.map { $0.filenameSuffix }
        XCTAssertTrue(suffixes.contains("light_large_portrait"))
        XCTAssertTrue(suffixes.contains("light_accessibilityLarge_portrait"))
        XCTAssertTrue(suffixes.contains("dark_large_portrait"))
        XCTAssertTrue(suffixes.contains("dark_accessibilityLarge_portrait"))
    }

    func testCartesianProduct_allAxes() {
        let matrix = VariantMatrix(variants: [
            .lightDark,
            .dynamicType([.large, .accessibilityLarge]),
            .orientations
        ])
        let combos = matrix.expand()
        // 2 color x 2 type x 2 orientation = 8
        XCTAssertEqual(combos.count, 8)
    }

    func testDefaultVariants() {
        let matrix = VariantMatrix(variants: [.lightDark])
        let combos = matrix.expand()
        XCTAssertEqual(combos[0].contentSizeCategory, .large)
        XCTAssertEqual(combos[0].orientation, .portrait)
    }

    func testEmptyVariantsProducesSingleDefault() {
        let matrix = VariantMatrix(variants: [])
        let combos = matrix.expand()
        XCTAssertEqual(combos.count, 1)
        XCTAssertEqual(combos[0].colorScheme, .light)
        XCTAssertEqual(combos[0].contentSizeCategory, .large)
        XCTAssertEqual(combos[0].orientation, .portrait)
    }

    // MARK: - VariantCombo trait collection

    func testTraitCollectionDarkMode() {
        let combo = VariantCombo(
            colorScheme: .dark,
            contentSizeCategory: .large,
            orientation: .portrait
        )
        let traits = combo.traitCollection
        XCTAssertEqual(traits.userInterfaceStyle, .dark)
    }

    func testTraitCollectionContentSize() {
        let combo = VariantCombo(
            colorScheme: .light,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge,
            orientation: .portrait
        )
        let traits = combo.traitCollection
        XCTAssertEqual(traits.preferredContentSizeCategory, .accessibilityExtraExtraExtraLarge)
    }
}
