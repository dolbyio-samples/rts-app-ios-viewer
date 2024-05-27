//
//  SettingsCell.swift
//

import SwiftUI

@available(tvOS, unavailable)
public struct SettingsCell: View {

    public let action: (() -> Void)
    public let text: LocalizedStringKey
    public let textColor: Color
    public var value: LocalizedStringKey
    public let valueColor: Color
    public let bundle: Bundle?
    public let image: IconAsset?

    public init(text: LocalizedStringKey,
                textColor: Color = .black,
                value: LocalizedStringKey,
                valueColor: Color = .gray,
                image: IconAsset? = nil,
                bundle: Bundle? = nil,
                action: @escaping (() -> Void) = {}
    ) {
        self.text = text
        self.textColor = textColor
        self.value = value
        self.valueColor = valueColor
        self.image = image
        self.bundle = bundle
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            HStack {

                    Text(
                        text,
                        bundle: bundle,
                        font: .custom("AvenirNext-Regular", size: FontSize.body),
                        textColor: textColor
                    )

                Spacer()

                    Text(
                        value,
                        bundle: bundle,
                        font: .custom("AvenirNext-Regular", size: FontSize.body),
                        textColor: valueColor
                    )

                if let imageRight = image {
                    IconView(iconAsset: imageRight)
                        .accessibilityIdentifier(text.toString())
                }
            }
        }
    }
}

@available(iOS 16.0, *)
@available(tvOS, unavailable)
struct SettingsCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                SettingsCell(text: "Audio selection",
                             value: "First source",
                             image: .textLink,
                             action: {}
                )
                .listRowSeparator(.visible)
            }
            .listRowBackground(Color.gray)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mint.edgesIgnoringSafeArea(.all))
    }
}
