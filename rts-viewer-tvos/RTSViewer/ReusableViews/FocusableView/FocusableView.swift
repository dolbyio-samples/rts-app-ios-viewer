//
//  FocusableView.swift
//

import SwiftUI

struct FocusableView<Content: View>: View {
    struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(.clear)
        }
    }

    private var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        Button(action: {}) {
            content()
        }
        .buttonStyle(Style())
    }
}
