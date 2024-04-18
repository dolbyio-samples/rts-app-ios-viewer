//
//  IconButton.swift
//  

import SwiftUI

public struct IconButton: View {
    private let text: LocalizedStringKey?
    private let name: ImageAsset
    private let tintColor: Color?
    private let focusedTintColor: Color?
    private let action: () -> Void

    @FocusState private var isFocused: Bool
    private var theme: Theme = ThemeManager.shared.theme

    public init(
        text: LocalizedStringKey? = nil,
        name: ImageAsset,
        tintColor: Color? = nil,
        focusedTintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.name = name
        self.tintColor = tintColor
        self.focusedTintColor = focusedTintColor
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: Layout.spacing2x) {
                if let text = text {
                    Text(
                        text: text,
                        fontAsset: .avenirNextRegular(
                            size: FontSize.caption1,
                            style: .title
                        ),
                        textColor: isFocused ? _focusedTintColor : _tintColor
                    )
                }
                IconView(
                    name: name,
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
        tintColor ?? theme[.iconButton(.tintColor)]
    }

    private var _focusedTintColor: Color? {
        focusedTintColor ?? theme[.iconButton(.focusedTintColor)]
    }
}

#if DEBUG
struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IconButton(name: .close, tintColor: .red, action: {})
            IconButton(text: "Close", name: .close, tintColor: .white, action: {})
        }
    }
}
#endif
