//
//  SelectionsScreen.swift
//

import SwiftUI

@available(tvOS, unavailable)
public struct SelectionsScreen: View {
    @Environment(\.presentationMode) var presentationMode

    var settings: [SelectionsGroup.Item]
    let footer: LocalizedStringKey?
    let footerBundle: Bundle?
    let onSelection: ((Int) -> Void)?

    public init(settings: [SelectionsGroup.Item],
                footer: LocalizedStringKey?,
                footerBundle: Bundle? = nil,
                onSelection: ((Int) -> Void)? = nil) {
        self.settings = settings
        self.footer = footer
        self.footerBundle = footerBundle
        self.onSelection = onSelection
    }

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            SelectionsGroup(settings: settings,
                            footer: footer,
                            bundle: footerBundle) { index in
                onSelection?(index)
                presentationMode.wrappedValue.dismiss()
            }
                            .listStyle(.plain)
                            .navigationBarBackButtonHidden()
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    IconButton(iconAsset: .chevronLeft, tintColor: .white, action: {
                                        presentationMode.wrappedValue.dismiss()
                                    })
                                }
                            }
        }
    }
}

@available(tvOS, unavailable)
struct SelectionsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SelectionsScreen(
            settings: [
                .init(key: "Key 1", selected: true),
                .init(key: "Key 2", selected: false),
                .init(key: "Key 3", selected: false)
            ],
            footer: "testD.localized.key",
            footerBundle: .module
        )
    }
}
