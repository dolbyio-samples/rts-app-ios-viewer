//
//  SwiftUIView.swift
//

import SwiftUI

public struct LinkButton: View {

    public let action: () -> Void
    public let text: LocalizedStringKey
    public let font: Font

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    private var theme: Theme = ThemeManager.shared.theme

    public init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        fontAsset: FontAsset
    ) {
        self.action = action
        self.text = text
        self.font = theme[fontAsset]
    }

    public init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        font: Font
    ) {
        self.action = action
        self.text = text
        self.font = font
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            SwiftUI.Text(text)
                .font(font)
                .foregroundColor(
                    Color(
                        uiColor: isFocused ? UIColor.CTA.focused : UIColor.Typography.Dark.primary
                    )
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
        LinkButton(action: { /* No-op */ }, text: "Click me!!", fontAsset: .avenirNextBold(size: FontSize.title1, style: .title))
    }
}
#endif
