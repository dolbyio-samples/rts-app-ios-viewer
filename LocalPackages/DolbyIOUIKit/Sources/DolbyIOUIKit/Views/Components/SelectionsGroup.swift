//
//  SelectionsGroup.swift
//

import SwiftUI

public struct SelectionsGroup: View {

    let actionOn: (Int) -> Void
    let footer: LocalizedStringKey?
    let footerBundle: Bundle?

    @Binding var settings: [Item]

    public struct Item: Hashable {
        public let key: LocalizedStringKey
        public var bundle: Bundle?
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

    public init(settings: Binding<[Item]>,
                footer: LocalizedStringKey? = nil,
                footerBundle: Bundle? = nil,
                actionOn: @escaping ((Int) -> Void) = { _ in }
    ) {
        self._settings = settings
        self.footer = footer
        self.footerBundle = footerBundle
        self.actionOn = actionOn
    }

    public var body: some View {
        List {
            Section {
                ForEach(settings.indices, id: \.self) { index in
                    SwiftUI.Button(action: {
                        settings.indices.forEach { i in
                            settings[i].selected = (index == i) ? true : false
                        }
                        actionOn(index)
                    }) {
                        HStack {
                            Text(
                                text: settings[index].key,
                                bundle: settings[index].bundle,
                                mode: .primary,
                                fontAsset: .avenirNextBold(
                                    size: FontSize.settings,
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
                         bundle: footerBundle,
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

struct SelectionsGroup_Previews: PreviewProvider {

    static var previews: some View {
        SelectionsGroup(settings: .constant([
            .init(key: "testA.localized.key", bundle: .module, selected: true),
            .init(key: "testB.localized.key", bundle: .module, selected: false),
            .init(key: "testC.localized.key", bundle: .module, selected: false)
        ]), footer: "testD.localized.key", footerBundle: .module) { index in
            print("index: \(index)")
        }
    }
}
