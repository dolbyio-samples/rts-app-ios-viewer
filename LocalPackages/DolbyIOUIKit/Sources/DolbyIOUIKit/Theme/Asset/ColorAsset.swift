//
//  Colors.swift
// 

import SwiftUI

public enum ColorAsset: ColorAssetable {

    case text(TextAsset)
    case textField(TextFieldAsset)
    case toggle(ToggleAsset)
    case icon(IconAsset)
    case iconButton(IconButtonAsset)
    case primaryButton(ButtonAsset)
    case primaryDangerButton(ButtonAsset)
    case secondaryButton(ButtonAsset)
    case secondaryDangerButton(ButtonAsset)

    // MARK: Text Colors

    public enum TextAsset {
        case primaryColor
        case secondaryColor
        case tertiaryColor
    }

    // MARK: TextField Colors

    public enum TextFieldAsset {
        case textColor
        case placeHolderTextColor
        case tintColor
        case outlineColor
        case activeOutlineColor
        case errorOutlineColor
        case disabledBackgroundColor
        case errorMessageColor
    }

    // MARK: Toggle Colors

    public enum ToggleAsset {
        case textColor
        case tintColor
        case focusedBackgroundColor
        case outlineColor
    }

    // MARK: Icon Colors

    public enum IconAsset {
        case tintColor
    }

    // MARK: IconButton Colors

    public enum IconButtonAsset {
        case tintColor
        case focusedTintColor
    }

    // MARK: Button Colors

    public enum ButtonAsset {
        case textColor
        case disabledTextColor
        case focusedTextColor
        case tintColor
        case disabledTintColor
        case focusedTintColor
        case backgroundColor
        case hoverBackgroundColor
        case disabledBackgroundColor
        case borderColor
        case disabledBorderColor
        case focusedBorderColor
    }
}
