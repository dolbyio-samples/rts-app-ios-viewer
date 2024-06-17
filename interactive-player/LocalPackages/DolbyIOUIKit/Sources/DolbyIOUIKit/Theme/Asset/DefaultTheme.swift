//
//  DefaultTheme.swift
//

import Foundation
import SwiftUI
import UIKit

// swiftlint:disable cyclomatic_complexity
public class DefaultTheme: Theme {

    private lazy var _primaryButtonAttribute: ButtonAttribute = primaryButtonAttribute()
    private lazy var _primaryDangerButtonAttribute: ButtonAttribute = primaryButtonDangerAttribute()
    private lazy var _secondaryButtonAttribute: ButtonAttribute = secondaryButtonAttribute()
    private lazy var _secondaryDangerButtonAttribute: ButtonAttribute = secondaryButtonDangerAttribute()
    private lazy var _tertiaryButtonAttribute: ButtonAttribute = tertiaryButtonAttribute()

    private lazy var _textFieldAttribute: TextFieldAttribute = textFieldAttributeValue()
    private lazy var _primaryTextAttribute: TextAttribute = primaryTextAttribute()
    private lazy var _secondaryTextAttribute: TextAttribute = secondaryTextAttribute()
    private lazy var _tertiaryTextAttribute: TextAttribute = tertiaryTextAttribute()

    private lazy var _toggleAttribute: ToggleAttribute = toggleAttributeValue()

    private lazy var _iconAttribute: IconAttribute = iconAttributeValue()

    // TODO: map to the right color of theme and use it for component attributes so that component attributes will not be required to be exposed in the theme.
    public let primary = UIColor.neonPurple400
    public let primaryContainer = UIColor.neonPurple400
    public let onPrimary = UIColor.white
    public let onPrimaryContainer = UIColor.white
    public let inversePrimary = UIColor.neonPurple400
    public let secondary = UIColor.neonPurple400
    public let secondaryContainer = UIColor.neonPurple400
    public let onSecondary = UIColor.neonPurple400
    public let onSecondaryContainer = UIColor.neonPurple400
    public let tertiary = UIColor.neonPurple400
    public let tertiaryContainer = UIColor.neonPurple400
    public let onTertiaryContainer = UIColor.neonPurple400
    public let surface = UIColor.neonPurple400
    public let surfaceDim = UIColor.neonPurple400
    public let surfaceBright = UIColor.neonPurple400
    public let surfaceContainerLowest = UIColor.neonPurple400
    public let surfaceContainerLow = UIColor.neonPurple400
    public let surfaceContainer = UIColor.neonPurple400
    public let surfaceContainerHigh = UIColor.neonPurple400
    public let surfaceContainerHighest = UIColor.neonPurple400
    public let surfaceVariant = UIColor.neonPurple400
    public let onSurface = UIColor.grey250
    public let onSurfaceVariant = UIColor.neonPurple400
    public let inverseSurface = UIColor.neonPurple400
    public let inverseOnSurface = UIColor.neonPurple400
    public let background = UIColor.black
    public let onBackground = UIColor.white
    public let error = UIColor.neonPurple400
    public let errorContainer = UIColor.neonPurple400
    public let onError = UIColor.neonPurple400
    public let onErrorContainer = UIColor.neonPurple400
    public let outline = UIColor.neonPurple400
    public let outlineVariant = UIColor.neonPurple400
    public let shadow = UIColor.neonPurple400
    public let surfaceTint = UIColor.neonPurple400
    public let scrim = UIColor.neonPurple400

    public let primary25 = UIColor.neonPurple25
    public let primary50 = UIColor.neonPurple50
    public let primary100 = UIColor.neonPurple100
    public let primary200 = UIColor.neonPurple200
    public let primary300 = UIColor.neonPurple300
    public let primary400 = UIColor.neonPurple400
    public let primary500 = UIColor.neonPurple500
    public let primary600 = UIColor.neonPurple600
    public let primary700 = UIColor.neonPurple700
    public let primary800 = UIColor.neonPurple800
    public let primary900 = UIColor.neonPurple900

    public let secondary25 = UIColor.ultraViolet100
    public let secondary50 = UIColor.ultraViolet100
    public let secondary100 = UIColor.ultraViolet100
    public let secondary200 = UIColor.ultraViolet200
    public let secondary300 = UIColor.ultraViolet300
    public let secondary400 = UIColor.ultraViolet400
    public let secondary500 = UIColor.ultraViolet500
    public let secondary600 = UIColor.ultraViolet600
    public let secondary700 = UIColor.ultraViolet600
    public let secondary800 = UIColor.ultraViolet600
    public let secondary900 = UIColor.ultraViolet600

    public let neutral25 = UIColor.grey25
    public let neutral50 = UIColor.grey50
    public let neutral100 = UIColor.grey100
    public let neutral200 = UIColor.grey200
    public let neutral300 = UIColor.grey300
    public let neutral400 = UIColor.grey400
    public let neutral500 = UIColor.grey500
    public let neutral600 = UIColor.grey600
    public let neutral700 = UIColor.grey700
    public let neutral800 = UIColor.grey800
    public let neutral900 = UIColor.grey900

    public let error25 = UIColor.red25
    public let error50 = UIColor.red50
    public let error100 = UIColor.red100
    public let error200 = UIColor.red200
    public let error300 = UIColor.red300
    public let error400 = UIColor.red400
    public let error500 = UIColor.red500
    public let error600 = UIColor.red600
    public let error700 = UIColor.red700
    public let error800 = UIColor.red800
    public let error900 = UIColor.red900

    public let success25 = UIColor.green25
    public let success50 = UIColor.green50
    public let success100 = UIColor.green100
    public let success200 = UIColor.green200
    public let success300 = UIColor.green300
    public let success400 = UIColor.green400
    public let success500 = UIColor.green500
    public let success600 = UIColor.green600
    public let success700 = UIColor.green700
    public let success800 = UIColor.green800
    public let success900 = UIColor.green900

    public let invalid25 = UIColor.yellow25
    public let invalid50 = UIColor.yellow50
    public let invalid100 = UIColor.yellow100
    public let invalid200 = UIColor.yellow200
    public let invalid300 = UIColor.yellow300
    public let invalid400 = UIColor.yellow400
    public let invalid500 = UIColor.yellow500
    public let invalid600 = UIColor.yellow600
    public let invalid700 = UIColor.yellow700
    public let invalid800 = UIColor.yellow800
    public let invalid900 = UIColor.yellow900

    public let info25 = UIColor.blue25
    public let info50 = UIColor.blue50
    public let info100 = UIColor.blue100
    public let info200 = UIColor.blue200
    public let info300 = UIColor.blue300
    public let info400 = UIColor.blue400
    public let info500 = UIColor.blue500
    public let info600 = UIColor.blue600
    public let info700 = UIColor.blue700
    public let info800 = UIColor.blue800
    public let info900 = UIColor.blue900
}

// MARK: Button attribute definitions
extension DefaultTheme {
    public func buttonAttribute(for buttonStyle: ButtonStyles) -> ButtonAttribute {
        switch buttonStyle {
        case .primary:
            return _primaryButtonAttribute
        case .primaryDanger:
            return _primaryDangerButtonAttribute
        case .secondary:
            return _secondaryButtonAttribute
        case .secondaryDanger:
            return _secondaryDangerButtonAttribute
        case .tertiary:
            return _tertiaryButtonAttribute
        }
    }

    private func primaryButtonAttribute() -> ButtonAttribute {
        return ButtonAttribute(
            textColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            disabledTextColor: Color(uiColor: UIColor(light: neutral600, dark: neutral600)),
            focusedTextColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            tintColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            disabledTintColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            focusedTintColor: Color(uiColor: UIColor(light: neutral600, dark: neutral600)),
            backgroundColor: Color(uiColor: UIColor(light: primary, dark: primary)),
            hoverBackgroundColor: Color(uiColor: UIColor(light: neutral25, dark: neutral25)),
            disabledBackgroundColor: Color(uiColor: UIColor(light: neutral200, dark: neutral200)),
            borderColor: Color(uiColor: UIColor(light: primary, dark: primary)),
            disabledBorderColor: Color(uiColor: UIColor(light: neutral200, dark: neutral200)),
            focusedBorderColor: Color(uiColor: UIColor(light: primary, dark: primary)))
    }

    private func primaryButtonDangerAttribute() -> ButtonAttribute {
        return ButtonAttribute(
            textColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            disabledTextColor: Color(uiColor: UIColor(light: neutral600, dark: neutral600)),
            focusedTextColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            tintColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            disabledTintColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            focusedTintColor: Color(uiColor: UIColor(light: neutral600, dark: neutral600)),
            backgroundColor: Color(uiColor: UIColor(light: primary, dark: primary)),
            hoverBackgroundColor: Color(uiColor: UIColor(light: neutral25, dark: neutral25)),
            disabledBackgroundColor: Color(uiColor: UIColor(light: neutral200, dark: neutral200)),
            borderColor: Color(uiColor: UIColor(light: primary, dark: primary)),
            disabledBorderColor: Color(uiColor: UIColor(light: neutral200, dark: neutral200)),
            focusedBorderColor: Color(uiColor: UIColor(light: primary, dark: primary)))
    }

    private func secondaryButtonAttribute() -> ButtonAttribute {
        return ButtonAttribute(
            textColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledTextColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            focusedTextColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            tintColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledTintColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            focusedTintColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            backgroundColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            hoverBackgroundColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledBackgroundColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            borderColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledBorderColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            focusedBorderColor: Color(uiColor: UIColor(light: primary25, dark: primary25)))
    }

    private func secondaryButtonDangerAttribute() -> ButtonAttribute {
        return ButtonAttribute(
            textColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledTextColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            focusedTextColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            tintColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledTintColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            focusedTintColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            backgroundColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            hoverBackgroundColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledBackgroundColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            borderColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            disabledBorderColor: Color(uiColor: UIColor(light: primary25, dark: primary25)),
            focusedBorderColor: Color(uiColor: UIColor(light: primary25, dark: primary25)))
    }

    private func tertiaryButtonAttribute() -> ButtonAttribute {
        return ButtonAttribute(
            textColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            disabledTextColor: Color(uiColor: UIColor(light: neutral600, dark: neutral600)),
            focusedTextColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            tintColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            disabledTintColor: Color(uiColor: UIColor(light: onPrimary, dark: onPrimary)),
            focusedTintColor: Color(uiColor: UIColor(light: neutral600, dark: neutral600)),
            backgroundColor: Color(uiColor: UIColor(light: primary, dark: primary)),
            hoverBackgroundColor: Color(uiColor: UIColor(light: neutral25, dark: neutral25)),
            disabledBackgroundColor: Color(uiColor: UIColor(light: neutral200, dark: neutral200)),
            borderColor: Color(uiColor: UIColor(light: primary, dark: primary)),
            disabledBorderColor: Color(uiColor: UIColor(light: neutral200, dark: neutral200)),
            focusedBorderColor: Color(uiColor: UIColor(light: primary, dark: primary)))
    }
}

// MARK: Icon attribute definitions
extension DefaultTheme {
    public func iconAttribute() -> IconAttribute {
        return _iconAttribute
    }

    private func iconAttributeValue() -> IconAttribute {
        return IconAttribute(tintColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)),
                                   focusedTintColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)))
    }

}

// MARK: Toggle attribute definitions
extension DefaultTheme {
    public func toggleAttribute() -> ToggleAttribute {
        return _toggleAttribute
    }

    private func toggleAttributeValue() -> ToggleAttribute {
        return ToggleAttribute(textColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)),
                               tintColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)),
                               focusedBackgroundColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), outlineColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)))
    }
}

// MARK: Text attribute definitions
extension DefaultTheme {
    public func textAttribute(for textStyle: TextStyles) -> TextAttribute {
        switch textStyle {
        case .displayLarge:
            return _primaryTextAttribute
        case .displayMedium:
            return _primaryTextAttribute
        case .displaySmall:
            return _primaryTextAttribute
        case .headlineLarge:
            return _primaryTextAttribute
        case .headlineMedium:
            return _primaryTextAttribute
        case .headlineSmall:
            return _primaryTextAttribute
        case .titleLarge:
            return _primaryTextAttribute
        case .titleMedium:
            return _primaryTextAttribute
        case .titleSmall:
            return _primaryTextAttribute
        case .labelLarge:
            return _secondaryTextAttribute
        case .labelMedium:
            return _secondaryTextAttribute
        case .labelSmall:
            return _secondaryTextAttribute
        case .bodyLarge:
            return _secondaryTextAttribute
        case .bodyMedium:
            return _secondaryTextAttribute
        case .bodySmall:
            return _secondaryTextAttribute
        }
    }

    private func primaryTextAttribute() -> TextAttribute {
        return TextAttribute(textColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)))
    }

    private func secondaryTextAttribute() -> TextAttribute {
        return TextAttribute(textColor: Color(uiColor: UIColor(light: onSurface, dark: onSurface)))
    }

    private func tertiaryTextAttribute() -> TextAttribute {
        return TextAttribute(textColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)))
    }
}

// MARK: TextField attribute definitions
extension DefaultTheme {

    public func textFieldAttribute() -> TextFieldAttribute {
        return _textFieldAttribute
    }

    private func textFieldAttributeValue() -> TextFieldAttribute {
        return TextFieldAttribute(textColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), placeHolderTextColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), tintColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), outlineColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), activeOutlineColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), errorOutlineColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), disabledBackgroundColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)), errorMessageColor: Color(uiColor: UIColor(light: onBackground, dark: onBackground)))
    }
}
// swiftlint:enable cyclomatic_complexity
