//
//  SelectionsScreen.swift
//

import SwiftUI

public struct SelectionsScreen: View {
    @Environment(\.presentationMode) var presentationMode

    @Binding var settings: [SelectionsGroup.Item]
    let footer: LocalizedStringKey?
    let footerBundle: Bundle?

    public init(settings: Binding<[SelectionsGroup.Item]>,
                footer: LocalizedStringKey?,
                footerBundle: Bundle? = nil) {
        self._settings = settings
        self.footer = footer
        self.footerBundle = footerBundle
    }

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            SelectionsGroup(settings: $settings,
                            footer: footer,
            footerBundle: footerBundle) { _ in
                presentationMode.wrappedValue.dismiss()
            }
                            .listStyle(.plain)
                            .navigationBarBackButtonHidden()
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    IconButton(name: .chevronLeft, tintColor: .white, action: {
                                        presentationMode.wrappedValue.dismiss()
                                    })
                                }
                            }
        }
    }
}

struct SelectionsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SelectionsScreen(settings: .constant([
            .init(key: "testA.localized.key", bundle: .module, selected: true),
            .init(key: "testB.localized.key", bundle: .module, selected: false),
            .init(key: "testC.localized.key", bundle: .module, selected: false)
        ]), footer: "testD.localized.key", footerBundle: .module)
    }
}
