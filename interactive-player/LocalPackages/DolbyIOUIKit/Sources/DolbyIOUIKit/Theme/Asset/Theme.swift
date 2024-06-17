//
//  Theme.swift
//  
import SwiftUI

public protocol Theme {
    // Material theme color definitions
    var primary: UIColor { get }
    var primaryContainer: UIColor { get }
    var onPrimary: UIColor { get }
    var onPrimaryContainer: UIColor { get }
    var inversePrimary: UIColor { get }
    var secondary: UIColor { get }
    var secondaryContainer: UIColor { get }
    var onSecondary: UIColor { get }
    var onSecondaryContainer: UIColor { get }
    var tertiary: UIColor { get }
    var tertiaryContainer: UIColor { get }
    var onTertiaryContainer: UIColor { get }
    var surface: UIColor { get }
    var surfaceDim: UIColor { get }
    var surfaceBright: UIColor { get }
    var surfaceContainerLowest: UIColor { get }
    var surfaceContainerLow: UIColor { get }
    var surfaceContainer: UIColor { get }
    var surfaceContainerHigh: UIColor { get }
    var surfaceContainerHighest: UIColor { get }
    var surfaceVariant: UIColor { get }
    var onSurface: UIColor { get }
    var onSurfaceVariant: UIColor { get }
    var inverseSurface: UIColor { get }
    var inverseOnSurface: UIColor { get }
    var background: UIColor { get }
    var onBackground: UIColor { get }
    var error: UIColor { get }
    var errorContainer: UIColor { get }
    var onError: UIColor { get }
    var onErrorContainer: UIColor { get }
    var outline: UIColor { get }
    var outlineVariant: UIColor { get }
    var shadow: UIColor { get }
    var surfaceTint: UIColor { get }
    var scrim: UIColor { get }

    var primary25: UIColor { get }
    var primary50: UIColor { get }
    var primary100: UIColor { get }
    var primary200: UIColor { get }
    var primary300: UIColor { get }
    var primary400: UIColor { get }
    var primary500: UIColor { get }
    var primary600: UIColor { get }
    var primary700: UIColor { get }
    var primary800: UIColor { get }
    var primary900: UIColor { get }

    var secondary25: UIColor { get }
    var secondary50: UIColor { get }
    var secondary100: UIColor { get }
    var secondary200: UIColor { get }
    var secondary300: UIColor { get }
    var secondary400: UIColor { get }
    var secondary500: UIColor { get }
    var secondary600: UIColor { get }
    var secondary700: UIColor { get }
    var secondary800: UIColor { get }
    var secondary900: UIColor { get }

    var neutral25: UIColor { get }
    var neutral50: UIColor { get }
    var neutral100: UIColor { get }
    var neutral200: UIColor { get }
    var neutral300: UIColor { get }
    var neutral400: UIColor { get }
    var neutral500: UIColor { get }
    var neutral600: UIColor { get }
    var neutral700: UIColor { get }
    var neutral800: UIColor { get }
    var neutral900: UIColor { get }

    var error25: UIColor { get }
    var error50: UIColor { get }
    var error100: UIColor { get }
    var error200: UIColor { get }
    var error300: UIColor { get }
    var error400: UIColor { get }
    var error500: UIColor { get }
    var error600: UIColor { get }
    var error700: UIColor { get }
    var error800: UIColor { get }
    var error900: UIColor { get }

    var success25: UIColor { get }
    var success50: UIColor { get }
    var success100: UIColor { get }
    var success200: UIColor { get }
    var success300: UIColor { get }
    var success400: UIColor { get }
    var success500: UIColor { get }
    var success600: UIColor { get }
    var success700: UIColor { get }
    var success800: UIColor { get }
    var success900: UIColor { get }

    var invalid25: UIColor { get }
    var invalid50: UIColor { get }
    var invalid100: UIColor { get }
    var invalid200: UIColor { get }
    var invalid300: UIColor { get }
    var invalid400: UIColor { get }
    var invalid500: UIColor { get }
    var invalid600: UIColor { get }
    var invalid700: UIColor { get }
    var invalid800: UIColor { get }
    var invalid900: UIColor { get }

    var info25: UIColor { get }
    var info50: UIColor { get }
    var info100: UIColor { get }
    var info200: UIColor { get }
    var info300: UIColor { get }
    var info400: UIColor { get }
    var info500: UIColor { get }
    var info600: UIColor { get }
    var info700: UIColor { get }
    var info800: UIColor { get }
    var info900: UIColor { get }

    func buttonAttribute(for buttonStyle: ButtonStyles) -> ButtonAttribute
    func iconAttribute() -> IconAttribute
    func toggleAttribute() -> ToggleAttribute
    func textAttribute(for textStyle: TextStyles) -> TextAttribute
    func textFieldAttribute() -> TextFieldAttribute
}

public enum ButtonStyles {
    case primary
    case primaryDanger
    case secondary
    case secondaryDanger
    case tertiary
}

public enum TextStyles {
    case displayLarge
    case displayMedium
    case displaySmall
    case headlineLarge
    case headlineMedium
    case headlineSmall
    case titleLarge
    case titleMedium
    case titleSmall
    case labelLarge
    case labelMedium
    case labelSmall
    case bodyLarge
    case bodyMedium
    case bodySmall
}
