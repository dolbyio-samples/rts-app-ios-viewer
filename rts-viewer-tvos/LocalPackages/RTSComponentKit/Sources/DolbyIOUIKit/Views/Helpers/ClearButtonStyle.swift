//
//  ClearButtonStyle.swift
//

import SwiftUI

public struct ClearButtonStyle: ButtonStyle {
    public let isFocused: Bool
    public let focusedBackgroundColor: Color?

    public init(isFocused: Bool, focusedBackgroundColor: Color?) {
        self.isFocused = isFocused
        self.focusedBackgroundColor = focusedBackgroundColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 48, minHeight: 48)
            .background(isFocused ? focusedBackgroundColor : .clear)
    }
}
