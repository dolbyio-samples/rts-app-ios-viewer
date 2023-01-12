//
//  IconButton.swift
//  

import SwiftUI

public struct IconButton: View {
    public var name: ImageAsset
    public var tintColor: Color?
    public var focusedBackgroundColor: Color?
    public var action: () -> Void

    @Environment(\.isFocused) private var isFocused: Bool
    private var theme: Theme = ThemeManager.shared.theme

    public init(
        name: ImageAsset,
        tintColor: Color? = nil,
        focusedBackgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.tintColor = tintColor
        self.focusedBackgroundColor = focusedBackgroundColor
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            IconView(
                name: name,
                tintColor: _tintColor
            )
        }
        .buttonStyle(
            ClearButtonStyle(isFocused: isFocused, focusedBackgroundColor: _focusedBackgroundColor)
        )
    }

    private var _tintColor: Color? {
        tintColor ?? theme[.icon(.tintColor)]
    }

    private var _focusedBackgroundColor: Color? {
        focusedBackgroundColor ?? theme[.iconButton(.focusedBackgroundColor)]
    }
}

#if DEBUG
struct IconButton_Previews: PreviewProvider {
    static var previews: some View {
        IconButton(name: .close, tintColor: .red, action: {})
    }
}
#endif
