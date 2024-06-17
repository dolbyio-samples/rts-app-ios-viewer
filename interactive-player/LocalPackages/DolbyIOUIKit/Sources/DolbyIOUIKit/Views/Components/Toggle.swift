//
//  Toggle.swift
//  

import SwiftUI

public struct Toggle: View {

    public var text: LocalizedStringKey
    @Binding public var isOn: Bool

    @FocusState private var isFocused: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    public init(text: LocalizedStringKey, isOn: Binding<Bool>) {
        self.text = text
        self._isOn = isOn
    }

    private var attribute: ToggleAttribute {
        themeManager.theme.toggleAttribute()
    }

    public var body: some View {
        SwiftUI.Button(action: {
            isOn.toggle()
        }) {
            SwiftUI.Toggle(text, isOn: $isOn)
                .toggleStyle(CheckboxToggleStyle())
                .font(font)
                .foregroundColor(textColor)
            #if os(tvOS)
                .focusable()
            #endif
        }
        .focused($isFocused)
        .buttonStyle(
            ClearButtonStyle(isFocused: isFocused, focusedBackgroundColor: focusedBackgroundColor)
        )
    }
}

private extension Toggle {
    var font: Font {
        .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
    }

    var textColor: Color? {
        attribute.textColor
    }

    var focusedBackgroundColor: Color? {
        attribute.focusedBackgroundColor
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    @ObservedObject private var themeManager = ThemeManager.shared

    private var attribute: ToggleAttribute {
        themeManager.theme.toggleAttribute()
    }

    func makeBody(configuration: Configuration) -> some View {
        return HStack(spacing: Layout.spacing2x) {
            IconView(
                iconAsset: .checkmark,
                tintColor: tintColor
            )
            .opacity(configuration.isOn ? 1 : 0)
            .padding(Layout.spacing0_5x)
            .overlay {
                if let outlineColor = outlineColor {
                    RoundedRectangle(cornerRadius: Layout.cornerRadius6x, style: .continuous)
                        .stroke(
                            outlineColor,
                            lineWidth: Layout.border2x
                        )
                }
            }

            configuration.label
        }
    }

    private var tintColor: Color? {
        attribute.tintColor
    }

    private var outlineColor: Color? {
        attribute.outlineColor
    }
}

#if DEBUG
struct Toggle_Previews: PreviewProvider {
    static var previews: some View {
        Toggle(text: "Toggle", isOn: .constant(true))
    }
}
#endif
