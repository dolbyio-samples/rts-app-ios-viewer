//
//  GridButtonStyle.swift
//

import SwiftUI

struct GridButtonStyle: ButtonStyle {
    var isFocused: Bool = false
    let focusedBorderColor: Color

    init(focusedView: ChannelGridView.FocusedView?, currentChannel: Channel, focusedBorderColor: Color) {
        if case let .gridView(channel) = focusedView {
            isFocused = currentChannel == channel
        }
        self.focusedBorderColor = focusedBorderColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .border(isFocused ? focusedBorderColor : .gray, width: 2)
    }
}
