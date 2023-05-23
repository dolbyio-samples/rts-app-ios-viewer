//
//  SettingsCell.swift
//

import SwiftUI

@available(tvOS, unavailable)
public struct SettingsCell: View {

    public let action: (() -> Void)
    public let text: LocalizedStringKey?
    public let textColor: Color
    public var value: LocalizedStringKey?
    public let valueColor: Color
    public let bundle: Bundle?
    public let image: ImageAsset?

    public init(text: LocalizedStringKey? = nil,
                textColor: Color = .black,
                value: LocalizedStringKey? = nil,
                valueColor: Color = .gray,
                image: ImageAsset? = nil,
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

                if let text = text {
                    Text(
                        text: text,
                        bundle: bundle,
                        mode: .primary,
                        fontAsset: .avenirNextRegular(
                            size: CGFloat(14.0),
                            style: .body
                        ),
                        textColor: textColor
                    )
                }

                Spacer()

                if let value = value {
                    Text(
                        text: value,
                        bundle: bundle,
                        mode: .primary,
                        fontAsset: .avenirNextRegular(
                            size: CGFloat(14.0),
                            style: .body
                        ),
                        textColor: valueColor
                    )
                }

                if let imageRight = image {
                    IconView(name: imageRight)
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
                SettingsCell(text: "testA.localized.key",
                             value: "Connection order",
                             image: .arrowRight,
                             bundle: .module,
                             action: {}
                )
                .listRowSeparator(.visible)

                SettingsCell(text: "Audio selection",
                             value: "First source",
                             image: .textLink,
                             action: {}
                ).listRowSeparator(.visible)
            }
            .listRowBackground(Color.gray)
        }
        .scrollContentBackground(.hidden)
        .background(Color.mint.edgesIgnoringSafeArea(.all))
    }
}
