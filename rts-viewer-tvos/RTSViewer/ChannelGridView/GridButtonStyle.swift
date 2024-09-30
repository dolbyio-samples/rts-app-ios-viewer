//
//  GridButtonStyle.swift
//

import SwiftUI

struct GridButtonStyle: ButtonStyle {
    let isFocused: Bool
    let focusedBorderColor: Color

    init(focusedView: ChannelGridView.FocusedView?, currentChannel: SourcedChannel, focusedBorderColor: Color) {
        if case let .gridView(channel) = focusedView {
            isFocused = currentChannel == channel
        } else {
            isFocused = false
        }
        self.focusedBorderColor = focusedBorderColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .border(isFocused ? focusedBorderColor : .gray, width: 2)
    }
}
