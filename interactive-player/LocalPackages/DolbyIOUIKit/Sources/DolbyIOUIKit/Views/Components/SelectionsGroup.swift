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
                                settings[index].key,
                                bundle: settings[index].bundle,
                                style: .titleMedium,
                                font: .custom("AvenirNext-Bold", size: CGFloat(14.0), relativeTo: .body)
                            )

                            Spacer()

                            if settings[index].selected {
                                IconView(iconAsset: .checkmark, tintColor: .green)
                            }
                        }
                    }
                }
            } footer: {
                if let footer = footer {
                    Text(
                        footer,
                        bundle: bundle,
                        style: .titleSmall,
                        font: .custom("AvenirNext-Regular", size: FontSize.caption1, relativeTo: .caption)
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
            SelectionsGroup(
                settings: [
                    .init(key: "Key 1", selected: true),
                    .init(key: "Key 2", selected: false),
                    .init(key: "Key 3", selected: false)
                ],
                footer: "testD.localized.key"
            ) { _ in
                // No-op
            }
        }
    }
}
