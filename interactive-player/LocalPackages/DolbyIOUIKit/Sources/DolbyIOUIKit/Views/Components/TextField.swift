//
//  TextField.swift
//  

import SwiftUI

@available(tvOS, unavailable)
@available(iOS 15, *)
public struct TextField: View {

    private enum LayoutConstants {
        static let placeHolderTextOffsetX: CGFloat = 15.0
        static let placeHolderTextOffsetY: CGFloat = -8.0
    }
    public typealias ValidationResult = (success: Bool, message: LocalizedStringKey?)

    @Binding public var text: String
    public let placeholderText: LocalizedStringKey?
    public var validate: (() -> ValidationResult)?

    @FocusState private var isFocused: Bool
    @State private var validationResult: ValidationResult?
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared

    @State var placeHolderTextSize: CGSize = .zero

    private var attribute: TextFieldAttribute {
        themeManager.theme.textFieldAttribute()
    }

    private var hasError: Bool {
        validationResult?.success ?? false
    }
    private var errorMessage: LocalizedStringKey? {
        validationResult?.message
    }

    public init(
        text: Binding<String>,
        placeholderText: LocalizedStringKey? = nil,
        validate: (() -> ValidationResult)? = nil
    ) {
        self._text = text
        self.placeholderText = placeholderText
        self.validate = validate
    }

    public var body: some View {
        VStack(alignment: .leading) {
            ZStack {
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
                    .frame(minHeight: 48)

                    IconButton(
                        iconAsset: .close,
                        tintColor: tintColor,
                        action: { text = "" }
                    )
                    .opacity(!text.isEmpty && isFocused ? 1.0 : 0.0)
                }
                .overlay {
                    ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                        if let placeholderText = placeholderText {
                            Text(
                                placeholderText,
                                font: Font.custom("AvenirNext-regular", size: FontSize.caption1, relativeTo: .caption)
                            )
                            .lineLimit(1)
                            .foregroundColor(placeholderTextColor)
                            .offset(x: LayoutConstants.placeHolderTextOffsetX, y: LayoutConstants.placeHolderTextOffsetY)
                            .background(ViewGeometry())
                            .onPreferenceChange(ViewSizeKey.self) {
                                placeHolderTextSize = $0
                            }
                        }

                        if let outlineColor = outlineColor {
                            TextFieldBorderShape(
                                startX: LayoutConstants.placeHolderTextOffsetX - 10,
                                endX: LayoutConstants.placeHolderTextOffsetX + placeHolderTextSize.width, cornerRadius: Layout.cornerRadius6x
                            )
                            .stroke(outlineColor, lineWidth: Layout.border2x)
                        }

                    }
                }
            }
            if let errorMessage = errorMessage {
                Text(errorMessage, font: errorFont)
                    .foregroundColor(errorMessageColor)
            }
        }
    }
}

@available(tvOS, unavailable)
private extension TextField {
    var font: Font {
        .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
    }

    var errorFont: Font {
        .custom("AvenirNext-Regular", size: FontSize.caption1, relativeTo: .caption)
    }

    var placeholderTextColor: Color? {
        attribute.placeHolderTextColor
    }

    var tintColor: Color? {
        attribute.tintColor
    }

    var outlineColor: Color? {
        switch (hasError, isFocused) {
        case (true, _):
            return attribute.errorOutlineColor
        case (false, true):
            return attribute.activeOutlineColor
        case (false, false):
            return attribute.outlineColor
        }
    }

    var errorMessageColor: Color? {
        attribute.errorMessageColor
    }
}

private struct InputTextFieldStyle: TextFieldStyle {
    let isFocused: Bool
    let hasError: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    private var attribute: TextFieldAttribute {
        themeManager.theme.textFieldAttribute()
    }

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
        attribute.textColor
    }
}

private struct TextFieldBorderShape: Shape {
    let startX: CGFloat
    let endX: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path: Path = Path()

        let topLeftCorner = rect.origin

        path.move(to: CGPoint(x: topLeftCorner.x, y: topLeftCorner.y + cornerRadius))
        path.addArc(center: CGPoint(x: topLeftCorner.x + cornerRadius, y: topLeftCorner.y + cornerRadius), radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        path.move(to: CGPoint(x: topLeftCorner.x + cornerRadius, y: topLeftCorner.y))
        path.addLine(to: CGPoint(x: topLeftCorner.x + cornerRadius + startX, y: topLeftCorner.y))

        path.move(to: CGPoint(x: topLeftCorner.x + cornerRadius + endX, y: topLeftCorner.y))

        let topRightCorner = CGPoint(x: rect.size.width, y: rect.origin.y)
        path.addLine(to: CGPoint(x: topRightCorner.x - cornerRadius, y: topRightCorner.y))
        path.addArc(center: CGPoint(x: topRightCorner.x - cornerRadius, y: topRightCorner.y + cornerRadius), radius: cornerRadius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)

        path.move(to: CGPoint(x: topRightCorner.x, y: topRightCorner.y + cornerRadius))

        let bottomRightCorner = CGPoint(x: rect.size.width, y: rect.size.height)
        path.addLine(to: CGPoint(x: bottomRightCorner.x, y: bottomRightCorner.y - cornerRadius))
        path.addArc(center: CGPoint(x: bottomRightCorner.x - cornerRadius, y: bottomRightCorner.y - cornerRadius), radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        path.move(to: CGPoint(x: bottomRightCorner.x - cornerRadius, y: bottomRightCorner.y))

        let bottomLeftCorner = CGPoint(x: rect.origin.x, y: rect.size.height)
        path.addLine(to: CGPoint(x: bottomLeftCorner.x + cornerRadius, y: bottomRightCorner.y))
        path.addArc(center: CGPoint(x: bottomLeftCorner.x + cornerRadius, y: bottomLeftCorner.y - cornerRadius), radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        path.move(to: CGPoint(x: bottomLeftCorner.x, y: bottomLeftCorner.y - cornerRadius))
        path.addLine(to: CGPoint(x: topLeftCorner.x, y: topLeftCorner.y + cornerRadius))

        return path
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
