//
//  LinkButton.swift
//

import SwiftUI

public struct LinkButton: View {

    public let action: () -> Void
    public let text: LocalizedStringKey
    public let font: Font

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
                        uiColor: isFocused ? UIColor.Typography.Dark.primary : UIColor.Typography.Dark.secondary
                    )
                )
                .padding()
                .overlay(
                    isFocused ? Rectangle()
                        .stroke(
                            Color(uiColor: UIColor.Neutral.neutral300),
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
        LinkButton(action: { /* No-op */ }, text: "Click me!!", fontAsset: .avenirNextBold(size: FontSize.title1, style: .title))
    }
}
#endif
