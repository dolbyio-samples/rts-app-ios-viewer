//
//  Button.swift
//

import SwiftUI

public struct Button: View {
    public enum ButtonState {
        case `default`
        case loading
        case success
    }

    public var action: () -> Void
    public var text: LocalizedStringKey

    public var leftIcon: IconAsset?
    public var rightIcon: IconAsset?
    public var style: ButtonStyles

    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding public var buttonState: ButtonState
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @State private var hover = false
    @FocusState private var isFocused: Bool

    public init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        leftIcon: IconAsset? = nil,
        rightIcon: IconAsset? = nil,
        style: ButtonStyles = .primary,
        buttonState: Binding<ButtonState> = .constant(.default)
    ) {
        self.action = action
        self.text = text
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.style = style
        self._buttonState = buttonState
    }

    private var attribute: ButtonAttribute {
        themeManager.theme.buttonAttribute(for: style)
    }

    public var body: some View {
        buttonView
    }
}

// MARK: Private helper functions

private extension Button {
    var buttonView: some View {
        SwiftUI.Button(action: action) {
            CustomButtonView(
                text: text,
                leftIcon: leftIcon,
                rightIcon: rightIcon,
                buttonAsset: attribute,
                isFocused: isFocused,
                buttonState: buttonState,
                backgroundColor: backgroundColor
            )
        }
        .focused($isFocused)
        .accessibilityLabel(accessibilityLabel)
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
        .frame(maxWidth: .infinity)
        .overlay(
            borderColorAndWidth.map {
                RoundedRectangle(cornerRadius: Layout.cornerRadius6x)
                    .stroke($0.color, lineWidth: $0.width)
            }
        )
        .background(backgroundColor)
        .mask(RoundedRectangle(cornerRadius: Layout.cornerRadius6x))
    }

    typealias BorderColorAndWidth = (color: Color, width: CGFloat)
    var borderColorAndWidth: BorderColorAndWidth? {
        switch (isEnabled, isFocused) {
        case (true, false):
            return (color: attribute.borderColor, width: Layout.border1x)
        case (true, true):
            return (color: attribute.focusedBorderColor, width: Layout.border1x)
        case (false, _):
            return (color: attribute.disabledBorderColor, width: Layout.border1x)
        }
    }

    var backgroundColor: Color? {
        guard isEnabled == true else {
            return attribute.disabledBackgroundColor
        }

        if isFocused {
            return attribute.hoverBackgroundColor
        }

        return attribute.backgroundColor
    }

    var accessibilityLabel: String {
        switch buttonState {
        case .default:
            return text.toString()
        case .loading:
            return "Loading..."
        case .success:
            return "Success"
        }
    }
}

// MARK: Defines the `View` for the Button's content

private struct CustomButtonView: View {
    private let text: LocalizedStringKey
    private let leftIcon: IconAsset?
    private let rightIcon: IconAsset?
    private let buttonAsset: ButtonAttribute
    private let isFocused: Bool
    private let buttonState: Button.ButtonState
    private let backgroundColor: Color?

    @Environment(\.isEnabled) private var isEnabled

    init(
        text: LocalizedStringKey,
        leftIcon: IconAsset?,
        rightIcon: IconAsset?,
        buttonAsset: ButtonAttribute,
        isFocused: Bool,
        buttonState: Button.ButtonState,
        backgroundColor: Color?
    ) {
        self.text = text
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.buttonAsset = buttonAsset
        self.isFocused = isFocused
        self.buttonState = buttonState
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            HStack(spacing: Layout.spacing2x) {
                if let leftIcon = leftIcon {
                    IconView(
                        iconAsset: leftIcon,
                        tintColor: tintColor
                    )
                }

                SwiftUI.Text(text)
                    .font(font)
                    .textCase(.uppercase)
                    .foregroundColor(textColor)

                if let rightIcon = rightIcon {
                    IconView(
                        iconAsset: rightIcon,
                        tintColor: tintColor
                    )
                }
            }
            .opacity(buttonState == .default ? 1.0 : 0.0)

            LoadingView(
                tintColor: tintColor
            )
            .opacity(buttonState == .loading ? 1.0 : 0.0)

            IconView(
                iconAsset: .success,
                tintColor: tintColor
            )
            .opacity(buttonState == .success ? 1.0 : 0.0)
        }
        .padding(.vertical, Layout.spacing1x)
        .padding(.horizontal, Layout.spacing4x)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(backgroundColor)
    }
}

private extension CustomButtonView {
    var font: Font {
        #if os(tvOS)
        theme[.avenirNextDemiBold(size: FontSize.caption2, withStyle: .caption2)]
        #else
        .custom("AvenirNext-DemiBold", size: FontSize.subhead, relativeTo: .subheadline)
        #endif
    }

    var textColor: Color? {
        guard isEnabled == true else {
            return buttonAsset.disabledTextColor
        }

        if isFocused {
            return buttonAsset.focusedTextColor
        }

        return buttonAsset.textColor
    }

    var tintColor: Color? {
        guard isEnabled == true else {
            return buttonAsset.disabledTintColor
        }

        if isFocused {
            return buttonAsset.focusedTintColor
        }

        return buttonAsset.tintColor
    }
}

#if DEBUG
struct PrimaryButton_Previews: PreviewProvider {

    static var previews: some View {
        Group {

            // MARK: Primary Buttons
            VStack {
                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    buttonState: .constant(.loading)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    buttonState: .constant(.success)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    buttonState: .constant(.default)
                )
                .disabled(true)
            }

            // MARK: Primary Danger Buttons
            VStack {
                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY DANGER BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .primaryDanger,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY DANGER BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .primaryDanger,
                    buttonState: .constant(.default)
                )
                .disabled(true)
            }

            // MARK: Secondary Buttons

            VStack {
                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .secondary,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .secondary,
                    buttonState: .constant(.loading)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .secondary,
                    buttonState: .constant(.success)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .secondary,
                    buttonState: .constant(.default)
                )
                .disabled(true)
            }

            // MARK: Secondary Danger Buttons

            VStack {

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY DANGER BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .secondaryDanger,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY DANGER BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    style: .secondaryDanger,
                    buttonState: .constant(.default)
                )
                .disabled(true)
            }
        }

    }
}
#endif
