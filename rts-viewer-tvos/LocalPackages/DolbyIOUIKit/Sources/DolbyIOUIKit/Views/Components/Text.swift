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

    private let text: LocalizedStringKey
    private let bundle: Bundle?
    private let mode: Mode
    private let font: Font
    private let textColor: Color?

    public init(
        text: LocalizedStringKey,
        bundle: Bundle? = nil,
        mode: Mode = .primary,
        font: Font,
        textColor: Color? = nil
    ) {
        self.text = text
        self.bundle = bundle
        self.mode = mode
        self.font = font
        self.textColor = textColor
    }

    public init(
        text: LocalizedStringKey,
        bundle: Bundle? = nil,
        mode: Mode = .primary,
        fontAsset: FontAsset,
        textColor: Color? = nil
    ) {
        self.text = text
        self.bundle = bundle
        self.mode = mode
        self.font = theme[fontAsset]
        self.textColor = textColor
    }

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme = ThemeManager.shared.theme

    public var body: some View {
        SwiftUI.Text(text, bundle: bundle)
            .foregroundColor(_textColor)
            .font(font)
    }
}

// MARK: Private helper functions

private extension Text {
    var _textColor: Color? {
        if let textColor = textColor {
            return textColor
        }

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
                    text: "testA.localized.key",
                    bundle: .module,
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
