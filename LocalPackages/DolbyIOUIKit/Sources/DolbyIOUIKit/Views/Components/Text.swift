//
//  Text.swift
//  

import SwiftUI

public struct Text: View {

    public enum Mode {
        case primary
        case secondary
        case tertiary
    }

    public var text: LocalizedStringKey
    public var mode: Mode
    public var font: Font

    public init(
        text: LocalizedStringKey,
        mode: Mode = .primary,
        font: Font
    ) {
        self.text = text
        self.mode = mode
        self.font = font
    }

    public init(
        text: LocalizedStringKey,
        mode: Mode = .primary,
        fontAsset: FontAsset
    ) {
        self.text = text
        self.mode = mode
        self.font = theme[fontAsset]
    }

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme = ThemeManager.shared.theme

    public var body: some View {
        SwiftUI.Text(text)
            .foregroundColor(textColor)
            .font(font)
    }
}

// MARK: Private helper functions

private extension Text {
    var textColor: Color? {
        switch mode {
        case .primary:
            return theme[.text(.primaryColor)]
        case .secondary:
            return theme[.text(.secondaryColor)]
        case .tertiary:
            return theme[.text(.tertiaryColor)]
        }
    }
}

#if DEBUG
struct Text_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Text(
                    text: "This is a regular text",
                    mode: .primary,
                    fontAsset: .avenirNextRegular(
                        size: FontSize.largeTitle,
                        style: .largeTitle
                    )
                )

                Text(
                    text: "This is a regular text",
                    mode: .primary,
                    fontAsset: .avenirNextRegular(
                        size: FontSize.title1,
                        style: .title
                    )
                )

                Text(
                    text: "This is a regular text",
                    mode: .primary,
                    fontAsset: .avenirNextRegular(
                        size: FontSize.title2,
                        style: .title2
                    )
                )

                Text(
                    text: "This is a regular text",
                    mode: .primary,
                    fontAsset: .avenirNextRegular(
                        size: FontSize.title3,
                        style: .title3
                    )
                )
            }

            VStack {
                Text(
                    text: "This is a bold text",
                    mode: .primary,
                    fontAsset: .avenirNextBold(
                        size: FontSize.largeTitle,
                        style: .largeTitle
                    )
                )

                Text(
                    text: "This is a bold text",
                    mode: .primary,
                    fontAsset: .avenirNextBold(
                        size: FontSize.title1,
                        style: .title
                    )
                )

                Text(
                    text: "This is a bold text",
                    mode: .primary,
                    fontAsset: .avenirNextBold(
                        size: FontSize.title2,
                        style: .title2
                    )
                )

                Text(
                    text: "This is a bold text",
                    mode: .primary,
                    fontAsset: .avenirNextBold(
                        size: FontSize.title3,
                        style: .title3
                    )
                )
            }
        }
    }
}
#endif
