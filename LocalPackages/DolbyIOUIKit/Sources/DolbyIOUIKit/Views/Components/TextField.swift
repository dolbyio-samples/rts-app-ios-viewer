//
//  TextField.swift
//  

import SwiftUI

@available(tvOS, unavailable)
@available(iOS 15, *)
public struct TextField: View {
    
    public typealias ValidationResult = (success: Bool, message: LocalizedStringKey?)
    
    @Binding public var text: String
    public let placeholderText: LocalizedStringKey
    public var validate: (() -> ValidationResult)?

    @FocusState private var isFocused: Bool
    @State private var validationResult: ValidationResult? = nil
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme = ThemeManager.shared.theme

    private var hasError: Bool {
        validationResult?.success ?? false
    }
    private var errorMessage: LocalizedStringKey? {
        validationResult?.message
    }

    public init(
        text: Binding<String>,
        placeholderText: LocalizedStringKey,
        validate: (() -> ValidationResult)?
    ) {
        self._text = text
        self.placeholderText = placeholderText
        self.validate = validate
    }

    public var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(text: placeholderText, font: font)
                        .padding([.leading, .trailing])
                        .foregroundColor(placeholderTextColor)
                }
                HStack(spacing: Layout.spacing0x) {
                    SwiftUI.TextField(
                        "",
                        text: $text,
                        onEditingChanged: { _ in
                            validationResult = nil
                        }
                    )
                    .textFieldStyle(
                        InputTextFieldStyle(
                            isFocused: isFocused,
                            hasError: hasError
                        )
                    )
                    .font(font)
                    .focused($isFocused)
                    .onSubmit {
                        validationResult = validate?()
                    }
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                    IconButton(
                        name: .close,
                        tintColor: tintColor,
                        action: { text = "" }
                    )
                    .opacity(text.isEmpty == false ? 1.0 : 0.0)
                }
                .overlay {
                    if let outlineColor = outlineColor {
                        RoundedRectangle(cornerRadius: Layout.cornerRadius6x, style: .continuous)
                            .stroke(outlineColor, lineWidth: Layout.border2x)
                    }
                }
            }
            if let errorMessage = errorMessage {
                Text(text: errorMessage, font: errorFont)
                    .foregroundColor(errorMessageColor)
            }
        }
    }
}

@available(tvOS, unavailable)
private extension TextField {
    var font: Font {
        theme[.avenirNextRegular(size: FontSize.subhead, style: .subheadline)]
    }
    
    var errorFont: Font {
        theme[.avenirNextRegular(size: FontSize.caption1, style: .caption)]
    }
    
    var placeholderTextColor: Color? {
        theme[ColorAsset.textField(.placeHolderTextColor)]
    }
    
    var tintColor: Color? {
        theme[ColorAsset.textField(.tintColor)]
    }
    
    var outlineColor: Color? {
        switch (hasError, isFocused) {
        case (true, _):
            return theme[ColorAsset.textField(.errorOutlineColor)]
        case (false, true):
            return theme[ColorAsset.textField(.activeOutlineColor)]
        case (false, false):
            return theme[ColorAsset.textField(.outlineColor)]
        }
    }
    
    var errorMessageColor: Color? {
        theme[ColorAsset.textField(.errorMessageColor)]
    }
}

fileprivate struct InputTextFieldStyle: TextFieldStyle {
    let isFocused: Bool
    let hasError: Bool
    private var theme: Theme = ThemeManager.shared.theme
    
    init(isFocused: Bool, hasError: Bool) {
        self.isFocused = isFocused
        self.hasError = hasError
    }

    func _body(configuration: SwiftUI.TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(textColor)
            .frame(minHeight: 48)
            .padding([.leading, .trailing])
    }
    
    var textColor: Color? {
        theme[ColorAsset.textField(.textColor)]
    }
}

#if DEBUG
@available(tvOS, unavailable)
struct TextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center) {
            TextField(
                text: .constant("Hello"),
                placeholderText: "Enter your stream name",
                validate: {
                    return (false, "Invalid username")
                }
            )
            
            TextField(
                text: .constant(""),
                placeholderText: "Enter your account ID",
                validate: {
                    return (true, nil)
                }
            )
        }
    }
}
#endif
