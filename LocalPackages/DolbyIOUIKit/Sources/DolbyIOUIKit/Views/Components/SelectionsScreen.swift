//
//  SelectionsScreen.swift
//

import SwiftUI

public struct SelectionsScreen: View {
    @Environment(\.presentationMode) var presentationMode

    @Binding var settings: [SelectionsGroup.Item]
    let footer: LocalizedStringKey?

    public init(settings: Binding<[SelectionsGroup.Item]>, footer: LocalizedStringKey?) {
        self._settings = settings
        self.footer = footer
    }

    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            SelectionsGroup(settings: $settings,
                            footer: footer) { _ in
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
            .init(key: "List view", selected: true),
            .init(key: "Grid view", selected: false),
            .init(key: "Single stream view", selected: false)
        ]), footer: "LocalizedStringKey")
    }
}
