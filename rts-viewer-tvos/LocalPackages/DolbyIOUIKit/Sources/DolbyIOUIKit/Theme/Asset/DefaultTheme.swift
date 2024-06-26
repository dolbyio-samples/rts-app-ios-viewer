//
//  DefaultTheme.swift
//

import Foundation
import SwiftUI
import UIKit

// swiftlint:disable cyclomatic_complexity

public class DefaultTheme: Theme {

    public override subscript(colorAsset: ColorAsset) -> Color? {
        switch colorAsset {
        case let .toggle(asset):
            return color(for: asset)
        case let .icon(asset):
            return color(for: asset)
        case let .iconButton(asset):
            return color(for: asset)
        case let .text(asset):
            return color(for: asset)
        case let .textField(asset):
            return color(for: asset)
        case let .primaryButton(asset):
            return primaryButtonColor(for: asset)
        case let .primaryDangerButton(asset):
            return primaryDangerButtonColor(for: asset)
        case let .secondaryButton(asset):
            return secondaryButtonColor(for: asset)
        case let .secondaryDangerButton(asset):
            return secondaryDangerButtonColor(for: asset)
        }
    }

    public override subscript(fontAsset: FontAsset) -> Font {
        return font(for: fontAsset)
    }

    public override subscript(imageAsset: ImageAsset) -> Image {
        return image(for: imageAsset)
    }
}

// MARK: Image Asset definitions

extension DefaultTheme {
    private func image(for imageAsset: ImageAsset) -> Image {
        return Image(imageAsset.rawValue, bundle: Bundle.module)
    }
}

// MARK: Font Asset definitions

extension DefaultTheme {
    private func font(for fontAsset: FontAsset) -> Font {
        switch fontAsset {
        case let .avenirNextRegular(size: size, style: style):
            return Font.avenirNextRegular(withStyle: style, size: size)
        case .avenirNextBold(size: let size, style: let style):
            return Font.avenirNextBold(withStyle: style, size: size)
        case .avenirNextMedium(size: let size, style: let style):
            return Font.avenirNextMedium(withStyle: style, size: size)
        case .avenirNextDemiBold(size: let size, style: let style):
            return Font.avenirNextDemiBold(withStyle: style, size: size)
        }
    }
}

// MARK: Theme color definitions

extension DefaultTheme {

    private func color(for toggleAsset: ColorAsset.ToggleAsset) -> Color? {
        switch toggleAsset {
        case .textColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Background.black,
                    dark: UIColor.Background.white
                )
            )
        case .tintColor:
            return Color(uiColor: UIColor.Secondary.emeraldGreen500)
        case .focusedBackgroundColor:
            return Color(uiColor: UIColor.Background.white)
        case .outlineColor:
            return Color(uiColor: UIColor.Neutral.neutral200)
        }
    }

    private func color(for iconAsset: ColorAsset.IconAsset) -> Color? {
        switch iconAsset {
        case .tintColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Background.black,
                    dark: UIColor.Background.white
                )
            )
        }
    }

    private func color(for iconButtonAsset: ColorAsset.IconButtonAsset) -> Color? {
        switch iconButtonAsset {
        case .tintColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Typography.Light.secondary,
                    dark: UIColor.Typography.Dark.secondary
                )
            )
        case .focusedTintColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Typography.Light.primary,
                    dark: UIColor.Typography.Dark.primary
                )
            )
        }
    }

    private func color(for textAsset: ColorAsset.TextAsset) -> Color? {
        switch textAsset {
        case .primaryColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Typography.Light.primary,
                    dark: UIColor.Typography.Dark.primary
                )
            )
        case .secondaryColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Typography.Light.secondary,
                    dark: UIColor.Typography.Dark.secondary
                )
            )
        case .tertiaryColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Typography.Light.tertiary,
                    dark: UIColor.Typography.Dark.tertiary
                )
            )
        }
    }

    private func color(for textFieldAsset: ColorAsset.TextFieldAsset) -> Color? {
        switch textFieldAsset {
        case .textColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Background.black,
                    dark: UIColor.Background.white
                )
            )
        case .placeHolderTextColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Typography.Dark.primary,
                    dark: UIColor.Typography.Light.primary
                )
            )

        case .tintColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Background.black,
                    dark: UIColor.Background.white
                )
            )

        case .outlineColor:
            return Color(uiColor: UIColor.Neutral.neutral100)

        case .activeOutlineColor:
            return Color(uiColor: UIColor.Primary.neonPurple400)

        case .errorOutlineColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .disabledBackgroundColor:
            return Color(uiColor: UIColor.Neutral.neutral25)

        case .errorMessageColor:
            return Color(uiColor: UIColor.Feedback.error500)

        }
    }

    private func primaryButtonColor(for buttonAsset: ColorAsset.ButtonAsset) -> Color? {
        switch buttonAsset {
        case .textColor:
            return Color(uiColor: UIColor.Typography.Dark.primary)

        case .focusedTextColor:
            return Color(uiColor: UIColor.Typography.Dark.tertiary)

        case .disabledTextColor:
            return Color(uiColor: UIColor.Typography.Dark.primary)

        case .tintColor:
            return Color(uiColor: UIColor.Background.white)

        case .disabledTintColor:
            return Color(uiColor: UIColor.Background.white)

        case .focusedTintColor:
            return Color(uiColor: UIColor.Typography.Dark.tertiary)

        case .backgroundColor:
            return Color(uiColor: UIColor.Primary.neonPurple400)

        case .hoverBackgroundColor:
            return Color(uiColor: UIColor.Neutral.neutral25)

        case .disabledBackgroundColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .borderColor:
            return nil

        case .disabledBorderColor:
            return nil

        case .focusedBorderColor:
            return nil
        }
    }

    private func primaryDangerButtonColor(for buttonAsset: ColorAsset.ButtonAsset) -> Color? {
        switch buttonAsset {
        case .textColor:
            return Color(uiColor: UIColor.Typography.Dark.primary)

        case .focusedTextColor:
            return Color(uiColor: UIColor.Typography.Dark.primary)

        case .disabledTextColor:
            return Color(uiColor: UIColor.Typography.Dark.primary)

        case .tintColor:
            return Color(uiColor: UIColor.Background.white)

        case .disabledTintColor:
            return Color(uiColor: UIColor.Background.white)

        case .focusedTintColor:
            return Color(uiColor: UIColor.Typography.Dark.primary)

        case .backgroundColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .hoverBackgroundColor:
            return Color(uiColor: UIColor.Feedback.error600)

        case .disabledBackgroundColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .borderColor:
            return nil

        case .disabledBorderColor:
            return nil

        case .focusedBorderColor:
            return nil
        }
    }

    private func secondaryButtonColor(for buttonAsset: ColorAsset.ButtonAsset) -> Color? {
        switch buttonAsset {
        case .textColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Primary.neonPurple400,
                    dark: UIColor.Background.white
                )
            )

        case .focusedTextColor:
            return Color(uiColor: UIColor.Typography.Dark.tertiary)

        case .disabledTextColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .tintColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Primary.neonPurple400,
                    dark: UIColor.Background.white
                )
            )

        case .disabledTintColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .focusedTintColor:
            return Color(uiColor: UIColor.Typography.Dark.tertiary)

        case .backgroundColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Neutral.neutral25,
                    dark: UIColor.Background.black
                )
            )

        case .hoverBackgroundColor:
            return Color(uiColor: UIColor.Neutral.neutral25)

        case .disabledBackgroundColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Background.white,
                    dark: UIColor.Neutral.neutral100
                        .withAlphaComponent(0.2)
                )
            )

        case .borderColor:
            return Color(uiColor: UIColor.Primary.neonPurple400)

        case .disabledBorderColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .focusedBorderColor:
            return nil
        }
    }

    private func secondaryDangerButtonColor(for buttonAsset: ColorAsset.ButtonAsset) -> Color? {
        switch buttonAsset {
        case .textColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .focusedTextColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .disabledTextColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .tintColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .disabledTintColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .focusedTintColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .backgroundColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Neutral.neutral25,
                    dark: UIColor.Background.black
                )
            )

        case .hoverBackgroundColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Primary.neonPurple25,
                    dark: UIColor.Feedback.error900
                )
            )

        case .disabledBackgroundColor:
            return Color(
                uiColor: UIColor(
                    light: UIColor.Background.white,
                    dark: UIColor.Feedback.error900
                )
            )

        case .borderColor:
            return Color(uiColor: UIColor.Feedback.error500)

        case .disabledBorderColor:
            return Color(uiColor: UIColor.Neutral.neutral200)

        case .focusedBorderColor:
            return Color(uiColor: UIColor.Feedback.error500)
        }
    }
}
// swiftlint:enable cyclomatic_complexity
