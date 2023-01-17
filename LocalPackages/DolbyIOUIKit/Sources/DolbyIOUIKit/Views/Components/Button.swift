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

    public enum Mode {
        case primary
        case secondary
    }

    public var action: () -> Void
    public var text: LocalizedStringKey
    public var leftIcon: ImageAsset?
    public var rightIcon: ImageAsset?
    public var mode: Mode
    public var danger: Bool
    private var theme: Theme = ThemeManager.shared.theme

    @Binding public var buttonState: ButtonState
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @State private var hover = false
    @FocusState private var isFocused: Bool

    public init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        leftIcon: ImageAsset? = nil,
        rightIcon: ImageAsset? = nil,
        mode: Mode = .primary,
        danger: Bool = false,
        buttonState: Binding<ButtonState> = .constant(.default)
    ) {
        self.action = action
        self.text = text
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.mode = mode
        self.danger = danger
        self._buttonState = buttonState
    }

    public var body: some View {
        if let borderColor = borderColorAndWidth?.color, let borderWidth = borderColorAndWidth?.width {
            buttonView
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius6x)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .mask(RoundedRectangle(cornerRadius: Layout.cornerRadius6x))
        } else {
            buttonView
                .cornerRadius(Layout.cornerRadius6x)
        }
    }
}

// MARK: Private helper functions

private extension Button {
    var buttonView: some View {
        SwiftUI.Button(action: action) {
            CustomButtonView(
                action: action,
                text: text,
                leftIcon: leftIcon,
                rightIcon: rightIcon,
                mode: mode,
                danger: danger,
                hover: $hover,
                buttonState: $buttonState
            )
        }
        .focused($isFocused)
        .accessibilityLabel(accessibilityLabel)
#if os(tvOS)
        .buttonStyle(
            ClearButtonStyle(
                isFocused: isFocused,
                focusedBackgroundColor: hoverBackgroundColor
            )
        )
#else
        .buttonStyle(.plain)
        .onHover {
            hover = $0
        }
#endif
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }

    typealias BorderColorAndWidth = (color: Color?, width: CGFloat?)
    var borderColorAndWidth: BorderColorAndWidth? {
        switch isEnabled {
        case true:
            return (color: borderColor, Layout.border1x)
        case false:
            return (color: disabledBorderColor, Layout.border1x)
        }
    }

    var borderColor: Color? {
        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.borderColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.borderColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.borderColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.borderColor)]
        }
    }

    var disabledBorderColor: Color? {
        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.disabledBorderColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.disabledBorderColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.disabledBorderColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.disabledBorderColor)]
        }
    }

    var backgroundColor: Color? {
        guard isEnabled == true else {
            return disabledBackgroundColor
        }

        if isFocused {
            return hoverBackgroundColor
        }

        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.backgroundColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.backgroundColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.backgroundColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.backgroundColor)]
        }
    }

    var hoverBackgroundColor: Color? {
        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.hoverBackgroundColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.hoverBackgroundColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.hoverBackgroundColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.hoverBackgroundColor)]
        }
    }

    var disabledBackgroundColor: Color? {
        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.disabledBackgroundColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.disabledBackgroundColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.disabledBackgroundColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.disabledBackgroundColor)]
        }
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
    var action: () -> Void
    var text: LocalizedStringKey
    var leftIcon: ImageAsset?
    var rightIcon: ImageAsset?
    var mode: Button.Mode
    var danger: Bool

    @Binding var hover: Bool
    @Binding var buttonState: Button.ButtonState

    @Environment(\.isEnabled) private var isEnabled
    private var theme: Theme = ThemeManager.shared.theme

    init(
        action: @escaping () -> Void,
        text: LocalizedStringKey,
        leftIcon: ImageAsset?,
        rightIcon: ImageAsset?,
        mode: Button.Mode,
        danger: Bool,
        hover: Binding<Bool>,
        buttonState: Binding<Button.ButtonState>
    ) {
        self.action = action
        self.text = text
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.mode = mode
        self.danger = danger
        self._hover = hover
        self._buttonState = buttonState
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            HStack(spacing: Layout.spacing2x) {
                if let leftIcon = leftIcon {
                    IconView(
                        name: leftIcon,
                        tintColor: tintColor
                    )
                }
                SwiftUI.Text(text)
                    .font(font)
                    .textCase(.uppercase)
                    .foregroundColor(textColor)
                if let rightIcon = rightIcon {
                    IconView(
                        name: rightIcon,
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
                name: .success,
                tintColor: tintColor
            )
            .opacity(buttonState == .success ? 1.0 : 0.0)
        }
        .padding(.vertical, Layout.spacing1x)
        .padding(.horizontal, Layout.spacing4x)
        .frame(minHeight: 44)
    }
}

private extension CustomButtonView {
    var font: Font {
        theme[.avenirNextDemiBold(size: FontSize.body, style: .body)]
    }
    var textColor: Color? {
        guard isEnabled == true else {
            return disabledTextColor
        }

        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.textColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.textColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.textColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.textColor)]
        }
    }

    var disabledTextColor: Color? {
        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.disabledTextColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.disabledTextColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.disabledTextColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.disabledTextColor)]
        }
    }

    var tintColor: Color? {
        guard isEnabled == true else {
            return disabledTintColor
        }

        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.tintColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.tintColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.tintColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.tintColor)]
        }
    }

    var disabledTintColor: Color? {
        switch (mode, danger) {
        case (.primary, false):
            return theme[ColorAsset.primaryButton(.disabledTintColor)]
        case (.primary, true):
            return theme[ColorAsset.primaryDangerButton(.disabledTintColor)]
        case (.secondary, false):
            return theme[ColorAsset.secondaryButton(.disabledTintColor)]
        case (.secondary, true):
            return theme[ColorAsset.secondaryDangerButton(.disabledTintColor)]
        }
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
                    danger: true,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "PRIMARY DANGER BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    danger: true,
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
                    mode: .secondary,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    mode: .secondary,
                    buttonState: .constant(.loading)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    mode: .secondary,
                    buttonState: .constant(.success)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    mode: .secondary,
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
                    mode: .secondary,
                    danger: true,
                    buttonState: .constant(.default)
                )

                Button(
                    action: {
                        print("Pressed Button 1")
                    },
                    text: "SECONDARY DANGER BUTTON TEXT",
                    leftIcon: .arrowLeft,
                    rightIcon: .arrowRight,
                    mode: .secondary,
                    danger: true,
                    buttonState: .constant(.default)
                )
                .disabled(true)
            }
        }

    }
}
#endif
