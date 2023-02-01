//
//  IconButton.swift
//  

import SwiftUI

public struct IconButton: View {
    public var name: ImageAsset
    public var tintColor: Color?
    public var focusedTintColor: Color?
    public var action: () -> Void

    @FocusState private var isFocused: Bool
    private var theme: Theme = ThemeManager.shared.theme

    public init(
        name: ImageAsset,
        tintColor: Color? = nil,
        focusedTintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.tintColor = tintColor
        self.focusedTintColor = focusedTintColor
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            IconView(
                name: name,
                tintColor: isFocused ? _focusedTintColor : _tintColor
            )
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
        IconButton(name: .close, tintColor: .red, action: {})
    }
}
#endif
