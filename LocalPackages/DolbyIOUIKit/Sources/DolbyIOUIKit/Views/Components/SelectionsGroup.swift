//
//  SelectionsGroup.swift
//

import SwiftUI

@available(tvOS, unavailable)
public struct SelectionsGroup: View {

    let onSelection: (Int) -> Void
    let footer: LocalizedStringKey?
    let bundle: Bundle?

    var settings: [Item]

    public struct Item: Hashable {
        public let key: LocalizedStringKey
        public let bundle: Bundle?
        public var selected: Bool

        public init(key: LocalizedStringKey,
                    bundle: Bundle? = nil,
                    selected: Bool) {
            self.key = key
            self.bundle = bundle
            self.selected = selected
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(key.stringKey)
        }
    }

    public init(settings: [Item],
                footer: LocalizedStringKey? = nil,
                bundle: Bundle? = nil,
                onSelection: @escaping ((Int) -> Void) = { _ in }
    ) {
        self.settings = settings
        self.footer = footer
        self.bundle = bundle
        self.onSelection = onSelection
    }

    public var body: some View {
        List {
            Section {
                ForEach(settings.indices, id: \.self) { index in
                    SwiftUI.Button(action: {
                        onSelection(index)
                    }) {
                        HStack {
                            Text(
                                text: settings[index].key,
                                bundle: settings[index].bundle,
                                mode: .primary,
                                fontAsset: .avenirNextBold(
                                    size: CGFloat(14.0),
                                    style: .body
                                )
                            )

                            Spacer()

                            if settings[index].selected {
                                IconView(name: .checkmark, tintColor: .green)
                            }
                        }
                    }
                }
            } footer: {
                if let footer = footer {
                    Text(text: footer,
                         bundle: bundle,
                         mode: .primary,
                         fontAsset: .avenirNextRegular(
                             size: FontSize.caption1,
                             style: .body
                         )
                    )
                }
            }
        }
    }
}

@available(tvOS, unavailable)
struct SelectionsGroup_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            SelectionsGroup(settings: [
                .init(key: "testA.localized.key", bundle: .module, selected: true),
                .init(key: "testB.localized.key", bundle: .module, selected: false),
                .init(key: "testC.localized.key", bundle: .module, selected: false)
            ], footer: "testD.localized.key", bundle: .module) { index in
                print("index: \(index)")
            }
        }
    }
}
