//
//  Toggle.swift
//  

import SwiftUI

public struct Toggle: View {

    public var text: LocalizedStringKey
    @Binding public var isOn: Bool

    @FocusState private var isFocused: Bool
    private var theme: Theme = ThemeManager.shared.theme

    public init(text: LocalizedStringKey, isOn: Binding<Bool>) {
        self.text = text
        self._isOn = isOn
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
        theme[.avenirNextRegular(size: FontSize.body, style: .body)]
    }

    var textColor: Color? {
        theme[ColorAsset.toggle(.textColor)]
    }

    var focusedBackgroundColor: Color? {
        theme[ColorAsset.toggle(.focusedBackgroundColor)]
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    private var theme: Theme = ThemeManager.shared.theme

    func makeBody(configuration: Configuration) -> some View {
        return HStack(spacing: Layout.spacing2x) {
            IconView(
                name: .checkmark,
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
        theme[ColorAsset.toggle(.tintColor)]
    }

    private var outlineColor: Color? {
        theme[ColorAsset.toggle(.outlineColor)]
    }
}

#if DEBUG
struct Toggle_Previews: PreviewProvider {
    static var previews: some View {
        Toggle(text: "Toggle", isOn: .constant(true))
    }
}
#endif
