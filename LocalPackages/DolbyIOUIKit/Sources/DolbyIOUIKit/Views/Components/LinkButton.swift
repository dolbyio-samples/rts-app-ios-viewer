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
    private var theme: Theme = ThemeManager.shared.theme

    public init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        fontAsset: FontAsset,
        padding: CGFloat? = nil
    ) {
        self.action = action
        self.text = text
        self.font = theme[fontAsset]
        self.padding = padding
    }

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

    public var body: some View {
        SwiftUI.Button(action: action) {
            SwiftUI.Text(text)
                .font(font)
                .foregroundColor(
                    Color(
                        uiColor: isFocused ? UIColor.Typography.Dark.primary : UIColor.Typography.Dark.secondary
                    )
                )
                .padding(.all, padding)
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
