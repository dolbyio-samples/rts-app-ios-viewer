//
//  SelectionsGroup.swift
//

import SwiftUI

public struct SelectionsGroup: View {

    let actionOn: (Int) -> Void
    let footer: LocalizedStringKey?

    @Binding var settings: [Item]

    public struct Item: Hashable {
        public var key: LocalizedStringKey
        public var selected: Bool

        public init(key: LocalizedStringKey, selected: Bool) {
            self.key = key
            self.selected = selected
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(key.stringKey)
        }
    }

    public init(settings: Binding<[Item]>,
                footer: LocalizedStringKey? = nil,
                actionOn: @escaping ((Int) -> Void) = { _ in }
    ) {
        self._settings = settings
        self.footer = footer
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
                                .init(key: "List view", selected: true),
                                .init(key: "Grid view", selected: false),
                                .init(key: "Single stream view", selected: false)
        ]), footer: "ABC") { index in
            print("index: \(index)")
        }
    }
}
