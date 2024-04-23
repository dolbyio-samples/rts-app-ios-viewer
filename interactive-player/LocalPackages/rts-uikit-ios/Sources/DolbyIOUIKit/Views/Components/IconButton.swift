//
//  IconButton.swift
//  

import SwiftUI

public struct IconButton: View {
    private let text: LocalizedStringKey?
    private let iconAsset: IconAsset
    private let tintColor: Color?
    private let focusedTintColor: Color?
    private let action: () -> Void

    @FocusState private var isFocused: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    private var attribute: IconAttribute {
        themeManager.theme.iconAttribute()
    }

    public init(
        text: LocalizedStringKey? = nil,
        iconAsset: IconAsset,
        tintColor: Color? = nil,
        focusedTintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.iconAsset = iconAsset
        self.tintColor = tintColor
        self.focusedTintColor = focusedTintColor
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: Layout.spacing2x) {
                if let text = text {
                    Text(
                        text,
                        font: .custom("AvenirNext-DemiBold", size: FontSize.caption1, relativeTo: .caption),
                        textColor: isFocused ? _focusedTintColor : _tintColor
                    )
                }
                IconView(
                    iconAsset: iconAsset,
                    tintColor: isFocused ? _focusedTintColor : _tintColor
                )
            }
        }
        .focused($isFocused)
        .buttonStyle(
            ClearButtonStyle(isFocused: isFocused, focusedBackgroundColor: .clear)
        )
    }

    private var _tintColor: Color? {
        tintColor ?? attribute.tintColor
    }

    private var _focusedTintColor: Color? {
        focusedTintColor ?? attribute.focusedTintColor
    }
}

#if DEBUG
struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IconButton(iconAsset: .close, tintColor: .red, action: {})
            IconButton(text: "Close", iconAsset: .close, tintColor: .white, action: {})
        }
    }
}
#endif
