//
//  LinkButton.swift
//

import SwiftUI

public struct LinkButton: View {

    public let action: () -> Void
    public let text: LocalizedStringKey
    public let font: Font
    public let padding: CGFloat?

    @FocusState private var isFocused: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    public init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        font: Font,
        padding: CGFloat? = nil
    ) {
        self.action = action
        self.text = text
        self.font = font
        self.padding = padding
    }

    private var theme: Theme {
        themeManager.theme
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            SwiftUI.Text(text)
                .font(font)
                .foregroundColor(
                    Color(
                        uiColor: isFocused ? theme.primary25 : theme.secondary25
                    )
                )
                .padding(.all, padding)
                .overlay(
                    isFocused ? Rectangle()
                        .stroke(
                            Color(uiColor: theme.neutral300),
                            lineWidth: Layout.border3x
                        ) : nil
                )
        }
        .focused($isFocused)
        .accessibilityLabel(text)
#if os(tvOS)
        .buttonStyle(
            ClearButtonStyle(
                isFocused: isFocused,
                focusedBackgroundColor: .clear
            )
        )
#else
        .buttonStyle(.plain)
#endif
        .background(.clear)
    }
}

#if DEBUG
struct LinkButton_Previews: PreviewProvider {
    static var previews: some View {
        LinkButton(action: { /* No-op */ }, text: "Click me!!", font: .custom("AvenirNext-DemiBold", size: FontSize.title1, relativeTo: .title))
    }
}
#endif
