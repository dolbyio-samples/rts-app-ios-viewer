//
//  Text.swift
//  

import SwiftUI

public struct Text: View {

    private let content: LocalizedContent
    private let bundle: Bundle?
    private let style: TextStyles
    private let font: Font
    private let textColor: Color?

    private enum LocalizedContent {
        case key(LocalizedStringKey)
        case verbatim(String)
    }

    @ObservedObject private var themeManager = ThemeManager.shared

    public init(
        _ key: LocalizedStringKey,
        bundle: Bundle? = nil,
        style: TextStyles = .labelMedium,
        font: Font,
        textColor: Color? = nil
    ) {
        self.content = .key(key)
        self.bundle = bundle
        self.style = style
        self.font = font
        self.textColor = textColor
    }

    public init(
        verbatim: String,
        bundle: Bundle? = nil,
        style: TextStyles = .labelMedium,
        font: Font,
        textColor: Color? = nil
    ) {
        self.content = .verbatim(verbatim)
        self.bundle = bundle
        self.style = style
        self.font = font
        self.textColor = textColor
    }

    private var attribute: TextAttribute {
        themeManager.theme.textAttribute(for: style)
    }

    private var _text: SwiftUI.Text {
        switch content {
        case let .key(localizedStringKey):
            return SwiftUI.Text(localizedStringKey, bundle: bundle)
        case let .verbatim(text):
            return SwiftUI.Text(verbatim: text)
        }
    }

    public var body: some View {
        _text
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

        return attribute.textColor
    }
}

#if DEBUG
struct Text_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Text(
                    verbatim: "This is a regular text",
                    style: .titleMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.title1, relativeTo: .title)
                )

                Text(
                    verbatim: "This is a regular text",
                    style: .titleMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.title2, relativeTo: .title2)
                )

                Text(
                    verbatim: "This is a regular text",
                    style: .titleMedium,
                    font: .custom("AvenirNext-Regular", size: FontSize.title3, relativeTo: .title3)
                )
            }

            VStack {
                Text(
                    verbatim: "This is a bold text",
                    style: .titleMedium,
                    font: .custom("AvenirNext-Bold", size: FontSize.title1, relativeTo: .title)
                )

                Text(
                    verbatim: "This is a bold text",
                    style: .titleMedium,
                    font: .custom("AvenirNext-Bold", size: FontSize.title2, relativeTo: .title2)
                )

                Text(
                    verbatim: "This is a bold text",
                    style: .titleMedium,
                    font: .custom("AvenirNext-Bold", size: FontSize.title1, relativeTo: .title3)
                )
            }
        }
    }
}
#endif
